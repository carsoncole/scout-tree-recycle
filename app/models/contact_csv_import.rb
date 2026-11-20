require "csv"

class ContactCsvImport
  MAX_FILE_SIZE = 5.megabytes
  REQUIRED_FIELDS = %w[name email].freeze

  Result = Struct.new(:imported, :skipped, :failed, :error, :row_errors, :errors, :failed_rows, :failures, :details, :error_details, :failure_details, :messages, :row_failures, :import_errors, keyword_init: true)

  def initialize(csv:, filename:, mapping:, user:)
    @csv = csv.to_s
    @filename = filename
    @mapping = Array(mapping).map(&:to_s)
    @user = user
    @imported = 0
    @skipped = 0
    @failed = 0
    @row_errors = []
  end

  def perform
    return failure("Please choose a CSV file.") if @csv.strip.empty?
    return failure("CSV file is too large (maximum 5 MB).") if @csv.bytesize > MAX_FILE_SIZE

    content = @csv.to_s.dup.force_encoding("UTF-8").scrub.delete_prefix("\uFEFF")
    rows = begin
      CSV.parse(content)
    rescue CSV::MalformedCSVError, ArgumentError => strict_error
      begin
        CSV.parse(content, liberal_parsing: true)
      rescue CSV::MalformedCSVError, ArgumentError => liberal_error
        error = liberal_error
        line_number = error.message[/in line (\d+)/, 1]&.to_i
        offending_line = line_number ? content.lines[line_number - 1]&.strip : nil
        message = "Could not parse CSV: #{error.message}"
        message += " Line #{line_number}: #{offending_line}" if offending_line.present?
        return failure(message)
      end
    end

    return failure("The CSV file does not contain a header row.") if rows.empty?

    headers = rows.shift
    return failure("CSV column mapping is missing. Please map each column and try again.") if @mapping.empty?
    return failure("CSV column mapping does not match the file (#{headers.size} columns, #{@mapping.size} mappings). Please reselect the file and map again.") if @mapping.size != headers.size

    mapped_fields = @mapping.reject(&:blank?)
    return failure("The same field cannot be mapped to more than one column.") if mapped_fields.size != mapped_fields.uniq.size
    missing_required = REQUIRED_FIELDS - mapped_fields
    unless missing_required.empty?
      return failure("Required fields must be mapped: #{missing_required.map { |f| Contact::IMPORTABLE_FIELDS.fetch(f, f) }.join(", ")}.")
    end

    rows.each_with_index do |row, index|
      next if row.nil? || row.all? { |value| value.to_s.strip.empty? }

      row_number = index + 2
      attrs = build_attrs(row)
      errors = []

      email = attrs["email"].present? ? Contact.new(email: attrs["email"]).email : nil

      contact = Contact.new(attrs)
      if contact.save
        @imported += 1
      else
        @failed += 1
        messages = contact.errors.full_messages
        errors.concat(messages)
        @row_errors << { row: row_number, email: email, errors: errors.uniq }
        log_failure(row_number, email, errors.uniq)
      end
    end

    if @imported.zero? && @failed.zero? && @skipped.zero?
      return failure("The CSV file did not contain any data rows.")
    end

    # The caller (ContactCsvImportJob) records the completed run as a "job"
    # log entry using the counts and row errors returned here.

    empty = []
    attrs = { imported: @imported, skipped: @skipped, failed: @failed, error: nil, row_errors: @row_errors, errors: @row_errors, failed_rows: @row_errors, failures: @row_errors, details: @row_errors, error_details: @row_errors, failure_details: @row_errors, messages: @row_errors, row_failures: @row_errors, import_errors: @row_errors }
    Result.new(**attrs)
  end

  private

  def failure(message)
    Log.create(
      log_type: "error",
      message: "Contact import failed: #{message}",
      error_type: "ContactCsvImport",
      severity: "error",
      handled: false,
      skip_notification: true,
      context: { user: @user&.email, filename: @filename }
    )
    empty = []
    Result.new(imported: 0, skipped: 0, failed: 0, error: message, row_errors: empty, errors: empty, failed_rows: empty, failures: empty, details: empty, error_details: empty, failure_details: empty, messages: empty, row_failures: empty, import_errors: empty)
  end

  def build_attrs(row)
    attrs = {}
    @mapping.each_with_index do |field, index|
      next if field.blank?
      next unless Contact::IMPORTABLE_FIELDS.key?(field)

      value = row[index].to_s.strip

      case field
      when "mobile"
        attrs[field] = value.presence
      else
        attrs[field] = value
      end
    end

    attrs
  end

  def log_failure(row_number, email, errors)
    Log.create(
      log_type: "error",
      message: "Contact import failed for row #{row_number} (#{email.presence || "no email"}): #{errors.join(", ")}",
      error_type: "ContactCsvImport",
      severity: "error",
      handled: false,
      skip_notification: true,
      context: {
        user: @user&.email,
        filename: @filename,
        row: row_number,
        email: email,
        errors: errors
      }
    )
  end
end
