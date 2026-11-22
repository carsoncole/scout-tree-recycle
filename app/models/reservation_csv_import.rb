require "csv"

# Restores reservations from the reservations.csv file inside a backup zip.
# Rows are matched to existing reservations by email: matching records are
# updated and missing ones are created. Restores never delete reservations and
# deliberately bypass model callbacks so a restore does not email customers,
# re-geocode, reroute, or write activity logs.
class ReservationCsvImport
  MAX_FILE_SIZE = 10.megabytes
  REQUIRED_HEADERS = %w[name email street].freeze
  NON_RESTORABLE_COLUMNS = %w[id route_id].freeze
  RESTORABLE_COLUMNS = (Reservation.column_names - NON_RESTORABLE_COLUMNS).freeze

  Result = Struct.new(:created, :updated, :skipped, :failed, :error, :row_errors, keyword_init: true) do
    def success?
      error.blank?
    end
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
    @touched_route_ids = Set.new
  end

  def perform
    return failure("Please choose a reservations CSV file.") if @csv.strip.empty?
    return failure("Reservations CSV file is too large (maximum 10 MB).") if @csv.bytesize > MAX_FILE_SIZE

    content = @csv.dup.force_encoding("UTF-8").scrub.delete_prefix("\uFEFF")
    rows = parse_rows(content)
    return rows if rows.is_a?(Result)

    headers = rows.headers.map { |header| header.to_s.strip }
    missing = REQUIRED_HEADERS - headers
    if missing.any?
      return failure("The CSV file is not a Tree Recycle reservations export. Missing columns: #{missing.join(', ')}.")
    end

    data_rows = 0
    seen_emails = Set.new

    rows.each.with_index(2) do |row, row_number|
      next if row.fields.all? { |value| value.to_s.strip.empty? }

      data_rows += 1
      attrs = build_attrs(row)
      email = attrs["email"].to_s.strip.downcase

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

    reconcile_route_counts
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
      # A blank status cell would otherwise override the model default with
      # nil, which is not a valid status. Keep the current/default status.
      next if key == "status" && value.to_s.strip.empty?

      attrs[key] = value.to_s
    end

    if row.headers.map { |header| header.to_s.strip }.include?("route")
      route_name = row["route"].to_s.strip
      attrs["route_id"] = route_name.present? ? route_id_for(route_name) : nil
    end

    if attrs["street_name"].blank?
      attrs["street_name"] = attrs["street"].to_s.sub(/^\d+\s*/, "")
    end

    attrs
  end

  def route_id_for(name)
    @route_ids_by_name ||= Route.order(:id).pluck(:name, :id).each_with_object({}) do |(route_name, id), routes|
      routes[route_name] ||= id
    end

    @route_ids_by_name[name]
  end

  def restore_row(row_number, email, attrs)
    if attrs["status"].present? && !Reservation.statuses.key?(attrs["status"])
      record_failure(row_number, email, [ "Status is not included in the list" ])
      return
    end

    if attrs["donation_type"].present? && !Reservation.donation_types.key?(attrs["donation_type"])
      record_failure(row_number, email, [ "Donation type is not included in the list" ])
      return
    end

    existing = Reservation.find_by(email: email)
    reservation = existing || Reservation.new
    reservation.importing = true
    reservation.assign_attributes(attrs)

    unless reservation.valid?
      record_failure(row_number, email, reservation.errors.full_messages)
      return
    end

    @touched_route_ids << existing.route_id if existing&.route_id.present?
    @touched_route_ids << reservation.route_id if reservation.route_id.present?

    if existing
      reservation.update_columns(reservation.attributes.slice(*attrs.keys))
      @updated += 1
    else
      attributes = reservation.attributes.except("id")
      attributes["created_at"] ||= Time.current
      attributes["updated_at"] ||= Time.current
      Reservation.insert_all([ attributes ])
      @created += 1
    end
  end

  # insert_all/update_columns skip the counter cache maintained by the
  # belongs_to association, so recalculate the routes this restore touched.
  def reconcile_route_counts
    return if @touched_route_ids.empty?

    Route.where(id: @touched_route_ids.to_a).find_each do |route|
      Route.reset_counters(route.id, :reservations)
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
      message: "Reservation restore failed: #{message}",
      error_type: "ReservationCsvImport",
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
      message: "Reservation restore failed for row #{row_number} (#{email.presence || "no email"}): #{errors.join(", ")}",
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
end
