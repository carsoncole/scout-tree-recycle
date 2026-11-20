# Deletes or fully resets application data. Backs the admin data management
# controls on /admin/settings/system. Destructive operations require a typed
# confirmation word that is validated server-side (see Admin::DataResetsController).
#
# Loading sample data is additive rather than destructive, so it is not a
# reset scope; it is handled by LoadSampleDataJob.
#
# Like EventClosure, this is a plain model object: controllers stay skinny and
# the destructive logic is testable on its own.
class DataReset
  SCOPES = %w[reservations contacts all].freeze

  # Destructive scopes require a typed confirmation word, validated
  # server-side.
  CONFIRMATION_WORDS = {
    "reservations" => "DELETE",
    "contacts" => "DELETE",
    "all" => "RESET ALL"
  }.freeze

  # Every application table, ordered so foreign keys are satisfied:
  # child rows are removed before the rows they reference.
  TABLES = %w[
    logs
    donations
    driver_routes
    points
    reservations
    routes
    drivers
    zones
    contacts
    sms
    thanks
    marketing_email_templates
    reservation_email_templates
    sessions
    users
    settings
  ].freeze

  Result = Struct.new(:scope, :deleted_count, :signed_out, keyword_init: true)

  def self.confirmation_word(scope)
    CONFIRMATION_WORDS.fetch(scope.to_s)
  end

  def self.confirmed?(scope, word)
    word.to_s.strip.casecmp?(confirmation_word(scope))
  end

  def initialize(scope:, user: nil)
    @scope = scope.to_s
    @user = user
  end

  def perform!
    case @scope
    when "reservations" then delete_reservations!
    when "contacts" then delete_contacts!
    when "all" then reset_all!
    else
      raise ArgumentError, "Unknown data reset scope: #{@scope}"
    end
  end

  private

  def delete_reservations!
    deleted_count = nil
    ActiveRecord::Base.transaction do
      # Mirrors Reservation's dependent: :nullify so donation records survive
      # detached (they are financial records, not reservation data).
      Donation.where.not(reservation_id: nil).update_all(reservation_id: nil)
      deleted_count = Reservation.delete_all
    end

    log_system_event("All reservations deleted (#{deleted_count}). Donations were kept but detached from their reservations.")
    Result.new(scope: @scope, deleted_count: deleted_count, signed_out: false)
  end

  def delete_contacts!
    deleted_count = Contact.delete_all

    log_system_event("All contacts deleted (#{deleted_count}).")
    Result.new(scope: @scope, deleted_count: deleted_count, signed_out: false)
  end

  def reset_all!
    # One transaction: if reloading the default templates fails, the
    # destructive deletes roll back instead of leaving an emptied database.
    # Sample data is not loaded here — it is a separate, manually triggered
    # action (see LoadSampleDataJob).
    ActiveRecord::Base.transaction do
      TABLES.each { |table| delete_table_rows!(table) }

      # Same defaults as `bin/rails db:seed`: built-in email templates.
      MarketingEmailTemplate.install_defaults!
      ReservationEmailTemplate.install_defaults!
    end

    log_system_event("All data was reset to defaults. Every application table was cleared and the default email templates were reloaded.")

    Result.new(scope: @scope, deleted_count: TABLES.size, signed_out: true)
  end

  def log_system_event(message)
    Log.create(
      log_type: "system",
      severity: "warning",
      message: message,
      handled: true,
      skip_notification: true,
      context: { user: @user&.email }
    )
  rescue StandardError => e
    Rails.logger.error("Data reset activity could not be logged: #{e.class}: #{e.message}")
  end

  def delete_table_rows!(table)
    ActiveRecord::Base.connection.execute("DELETE FROM #{ActiveRecord::Base.connection.quote_table_name(table)}")
  end
end
