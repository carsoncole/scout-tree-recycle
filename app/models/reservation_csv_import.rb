require "csv"

class ReservationCsvImport
  MAX_FILE_SIZE = 5.megabytes
  REQUIRED_FIELDS = %w[name street email].freeze
  DONATION_TYPE_ALIASES = {
    "cash_or_check" => "cash_or_check_donation",
    "cash" => "cash_or_check_donation",
    "check" => "cash_or_check_donation",
    "online" => "online_donation",
    "none" => "no_donation",
    "no_donation" => "no_donation"
  }.freeze

  Result = Struct.new(:imported, :skipped, :failed, :error, keyword_init: true)

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
    rescue CSV::MalformedCSVError, ArgumentError => e
      return failure("Could not parse CSV: #{e.message}")
    end

    return failure("The CSV file does not contain a header row.") if rows.empty?

    headers = rows.shift
    return failure("CSV column mapping is missing. Please map each column and try again.") if @mapping.empty?
    return failure("CSV column mapping does not match the file (#{headers.size} columns, #{@mapping.size} mappings). Please reselect the file and map again.") if @mapping.size != headers.size

    mapped_fields = @mapping.reject(&:blank?)
    return failure("The same field cannot be mapped to more than one column.") if mapped_fields.size != mapped_fields.uniq.size
    missing_required = REQUIRED_FIELDS - mapped_fields
    unless missing_required.empty?
      return failure("Required fields must be mapped: #{missing_required.map { |f| Reservation::IMPORTABLE_FIELDS.fetch(f, f) }.join(", ")}.")
    end

    email_index = @mapping.index("email")
    csv_emails = if email_index
      rows.map { |r| r[email_index].to_s.strip }.reject(&:empty?).map { |e| Reservation.new(email: e).email }
    else
      []
    end
    existing_emails = Reservation.where(email: csv_emails).pluck(:email).to_set

    rows.each_with_index do |row, index|
      next if row.nil? || row.all? { |value| value.to_s.strip.empty? }

      row_number = index + 2
      attrs = build_attrs(row)
      errors = []

      validate_status(attrs, errors)
      validate_donation_type(attrs, errors)

      email = attrs["email"].present? ? Reservation.new(email: attrs["email"]).email : nil
      if email.present? && existing_emails.include?(email)
        @skipped += 1
        log_skipped(row_number, email)
        next
      end

      reservation = Reservation.new(attrs)
      reservation.importing = true
      if reservation.save
        @imported += 1
        existing_emails << email if email.present?
      else
        @failed += 1
        messages = reservation.errors.full_messages
        errors.concat(messages)
        @row_errors << { row: row_number, email: email, errors: errors.uniq }
        log_failure(row_number, email, errors.uniq)
      end
    end

    if @imported.zero? && @failed.zero? && @skipped.zero?
      return failure("The CSV file did not contain any data rows.")
    end

    Result.new(imported: @imported, skipped: @skipped, failed: @failed, error: nil)
  end

  private

  def failure(message)
    Log.create(
      message: "Reservation import failed: #{message}",
      error_type: "ReservationCsvImport",
      severity: "error",
      handled: false,
      skip_notification: true,
      context: { user: @user&.email, filename: @filename }
    )
    Result.new(imported: 0, skipped: 0, failed: 0, error: message)
  end

  def build_attrs(row)
    attrs = {}
    @mapping.each_with_index do |field, index|
      next if field.blank?

      value = row[index].to_s.strip

      case field
      when "status"
        attrs[field] = value.presence || "imported"
      when "donation_type", "latitude", "longitude", "created_at", "updated_at"
        attrs[field] = value.presence
      else
        # Skip blank city/state/country so Reservation defaults apply.
        next if value.empty? && %w[city state country].include?(field)
        attrs[field] = value
      end
    end

    attrs["status"] = "imported" if attrs["status"].blank?
    attrs
  end

  def validate_status(attrs, errors)
    return if attrs["status"].blank?

    key = attrs["status"].to_s.strip.parameterize(separator: "_")
    key = "imported" if key.blank?
    unless Reservation.statuses.key?(key)
      errors << "Status '#{attrs["status"]}' is not valid."
      attrs.delete("status")
      return
    end
    attrs["status"] = key
  end

  def validate_donation_type(attrs, errors)
    return if attrs["donation_type"].blank?

    value = attrs["donation_type"].to_s.strip
    key = value.parameterize(separator: "_")
    key = DONATION_TYPE_ALIASES.fetch(key, key)
    unless Reservation.donation_types.key?(key)
      errors << "Donation type '#{value}' is not valid."
      attrs.delete("donation_type")
      return
    end
    attrs["donation_type"] = key
  end

  def log_failure(row_number, email, errors)
    Log.create(
      message: "Reservation import failed for row #{row_number} (#{email.presence || "no email"}): #{errors.join(", ")}",
      error_type: "ReservationCsvImport",
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

  def log_skipped(row_number, email)
    Log.create(
      message: "Reservation import skipped row #{row_number} (#{email}): email already exists.",
      error_type: "ReservationCsvImport",
      severity: "warning",
      handled: true,
      skip_notification: true,
      context: {
        user: @user&.email,
        filename: @filename,
        row: row_number,
        email: email
      }
    )
  end
end
