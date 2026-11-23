require "csv"

# Restores contacts from the contacts.csv file inside a backup zip. Rows are
# matched to existing contacts by email: matching records are updated and
# missing ones are created. Restores never delete contacts. The file is read
# by header name, so the columns written by Contact.to_csv restore without any
# column mapping.
class ContactsRestore
  MAX_FILE_SIZE = 10.megabytes
  REQUIRED_HEADERS = %w[name email].freeze
  RESTORABLE_COLUMNS = Contact::EXPORT_FIELDS.freeze
  # Leave these columns alone when the backup cell is blank so the model
  # default applies instead of writing an empty string.
  KEEP_ON_BLANK_COLUMNS = %w[
    marketing_1_email_sent_at
    marketing_2_email_sent_at
    is_unsubscribed_from_marketing
  ].freeze

  Result = Struct.new(:created, :updated, :skipped, :failed, :error, :row_errors, keyword_init: true) do
    def success?
      error.blank?
    end
  end

  def self.export
    Contact.to_csv
  end

  def initialize(csv:, filename:, user: nil)
    @csv = csv.to_s
    @filename = filename
    @user = user
    @created = 0
    @updated = 0
    @skipped = 0
    @failed = 0
    @row_errors = []
  end

  def perform
    return failure("Please choose a contacts CSV file.") if @csv.strip.empty?
    return failure("Contacts CSV file is too large (maximum 10 MB).") if @csv.bytesize > MAX_FILE_SIZE

    content = @csv.dup.force_encoding("UTF-8").scrub.delete_prefix("\uFEFF")
    rows = parse_rows(content)
    return rows if rows.is_a?(Result)

    headers = rows.headers.map { |header| header.to_s.strip }
    missing = REQUIRED_HEADERS - headers
    if missing.any?
      return failure("The CSV file is not a Tree Recycle contacts export. Missing columns: #{missing.join(', ')}.")
    end

    data_rows = 0
    seen_emails = Set.new

    rows.each.with_index(2) do |row, row_number|
      next if row.fields.all? { |value| value.to_s.strip.empty? }

      data_rows += 1
      attrs = build_attrs(row)
      email = attrs["email"].to_s.strip

      if email.blank?
        record_failure(row_number, nil, [ "Email can't be blank" ])
        next
      end

      if seen_emails.include?(email)
        @skipped += 1
        @row_errors << { row: row_number, email: email, errors: [ "Duplicate email in the backup; skipped." ] }
        next
      end

      seen_emails << email

      begin
        restore_row(row_number, email, attrs)
      rescue ArgumentError, ActiveRecord::ActiveRecordError => e
        record_failure(row_number, email, [ e.message ])
      end
    end

    return failure("The CSV file did not contain any data rows.") if data_rows.zero?

    result
  rescue CSV::MalformedCSVError => e
    failure("Could not parse CSV: #{e.message}")
  end

  private

  def parse_rows(content)
    CSV.parse(content, headers: true)
  rescue CSV::MalformedCSVError, ArgumentError
    begin
      CSV.parse(content, headers: true, liberal_parsing: true)
    rescue CSV::MalformedCSVError, ArgumentError => liberal_error
      failure("Could not parse CSV: #{liberal_error.message}")
    end
  end

  def build_attrs(row)
    attrs = {}

    row.each do |header, value|
      key = header.to_s.strip
      next unless RESTORABLE_COLUMNS.include?(key)

      value = value.to_s.strip
      next if value.empty? && KEEP_ON_BLANK_COLUMNS.include?(key)

      attrs[key] = value
    end

    if attrs["email"].present?
      attrs["email"] = Contact.new(email: attrs["email"]).email
    end

    attrs
  end

  def restore_row(row_number, email, attrs)
    existing = Contact.find_by(email: email)
    contact = existing || Contact.new

    if contact.update(attrs)
      existing ? @updated += 1 : @created += 1
    else
      record_failure(row_number, email, contact.errors.full_messages)
    end
  end

  def record_failure(row_number, email, errors)
    @failed += 1
    @row_errors << { row: row_number, email: email, errors: errors }
    log_failure(row_number, email, errors)
  end

  def result
    Result.new(
      created: @created,
      updated: @updated,
      skipped: @skipped,
      failed: @failed,
      error: nil,
      row_errors: @row_errors
    )
  end

  def failure(message)
    Log.create(
      log_type: "error",
      message: "Contact restore failed: #{message}",
      error_type: "ContactsRestore",
      severity: "error",
      handled: false,
      skip_notification: true,
      context: { user: @user&.email, filename: @filename }
    )

    Result.new(created: 0, updated: 0, skipped: 0, failed: 0, error: message, row_errors: [])
  end

  def log_failure(row_number, email, errors)
    Log.create(
      log_type: "error",
      message: "Contact restore failed for row #{row_number} (#{email.presence || "no email"}): #{errors.join(", ")}",
      error_type: "ContactsRestore",
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
