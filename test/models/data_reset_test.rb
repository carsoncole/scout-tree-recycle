require "test_helper"

class DataResetTest < ActiveSupport::TestCase
  test "confirmation words map to scopes" do
    assert_equal "DELETE", DataReset.confirmation_word("reservations")
    assert_equal "DELETE", DataReset.confirmation_word("contacts")
    assert_equal "RESET ALL", DataReset.confirmation_word("all")
  end

  test "every scope requires a confirmation word" do
    DataReset::SCOPES.each do |scope|
      assert DataReset::CONFIRMATION_WORDS.key?(scope), "expected a confirmation word for #{scope}"
    end
  end

  test "confirmed? matches the scope's word case-insensitively" do
    assert DataReset.confirmed?("reservations", "delete")
    assert DataReset.confirmed?("reservations", "  DELETE  ")
    assert DataReset.confirmed?("all", "reset all")
    assert_not DataReset.confirmed?("all", "delete")
    assert_not DataReset.confirmed?("all", "")
    assert_not DataReset.confirmed?("contacts", nil)
  end

  test "raises for an unknown scope" do
    assert_raises(ArgumentError) do
      DataReset.new(scope: "users").perform!
    end

    # Loading sample data is handled by LoadSampleDataJob, not DataReset.
    assert_raises(ArgumentError) do
      DataReset.new(scope: "sample_data").perform!
    end
  end

  test "deleting all reservations keeps contacts and detaches donations" do
    donation = donations(:one)
    assert_not_nil donation.reservation_id
    contacts_count = Contact.count
    reservations_count = Reservation.count

    result = DataReset.new(scope: "reservations", user: users(:admin)).perform!

    assert_not result.signed_out
    assert_equal reservations_count, result.deleted_count
    assert_equal 0, Reservation.count
    assert_equal contacts_count, Contact.count

    donation.reload
    assert_nil donation.reservation_id

    log = Log.order(:created_at).last
    assert_equal "system", log.log_type
    assert_includes log.message, "All reservations deleted"
    assert_equal users(:admin).email, log.context["user"]
  end

  test "deleting all contacts keeps reservations" do
    reservations_count = Reservation.count

    result = DataReset.new(scope: "contacts", user: users(:admin)).perform!

    assert_not result.signed_out
    assert_equal 0, Contact.count
    assert_equal reservations_count, Reservation.count

    log = Log.order(:created_at).last
    assert_includes log.message, "All contacts deleted"
  end

  test "resetting all data clears every application table and reloads defaults without sample data" do
    result = DataReset.new(scope: "all", user: users(:admin)).perform!

    assert result.signed_out

    # The reset intentionally leaves a record of itself in the logs and
    # reinstalls the default email templates. Everything else is empty.
    (DataReset::TABLES - %w[logs marketing_email_templates reservation_email_templates]).each do |table|
      assert_equal 0, ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{ActiveRecord::Base.connection.quote_table_name(table)}"),
        "expected #{table} to be empty"
    end
    assert_equal 1, Log.count
    assert_equal 0, Reservation.count, "sample data should not be loaded by the reset"
    assert_equal 0, Contact.count

    assert_equal MarketingEmailTemplate.default_names.sort, MarketingEmailTemplate.pluck(:name).sort
    assert_equal ReservationEmailTemplate.default_names.sort, ReservationEmailTemplate.pluck(:name).sort
    assert_predicate MarketingEmailTemplate.find_by(name: "marketing_email_1"), :published?

    log = Log.order(:created_at).last
    assert_equal "system", log.log_type
    assert_includes log.message, "All data was reset to defaults"
    assert_equal users(:admin).email, log.context["user"]
  end
end
