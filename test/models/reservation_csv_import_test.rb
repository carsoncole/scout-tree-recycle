require "test_helper"
require "csv"

class ReservationCsvImportTest < ActiveSupport::TestCase
  test "creates reservations from a backup csv" do
    csv = csv_with_rows(
      "name" => "Restored Person",
      "email" => "restored.person@example.com",
      "street" => "123 Main St",
      "status" => "pending_pickup",
      "created_at" => "2026-01-01T10:00:00Z",
      "updated_at" => "2026-01-01T10:05:00Z"
    )

    result = import(csv)

    assert result.success?
    assert_equal 1, result.created
    assert_equal 0, result.failed

    reservation = Reservation.find_by(email: "restored.person@example.com")
    assert reservation
    assert_equal "Restored Person", reservation.name
    assert_equal "pending_pickup", reservation.status
    assert_equal Time.zone.parse("2026-01-01T10:00:00Z"), reservation.created_at
    assert_equal Time.zone.parse("2026-01-01T10:05:00Z"), reservation.updated_at
  end

  test "updates an existing reservation matched by email" do
    existing = reservations(:pending_pickup_1)
    csv = csv_with_rows(
      "name" => "Updated Name",
      "email" => existing.email,
      "street" => existing.street,
      "status" => "picked_up"
    )

    result = import(csv)

    assert result.success?
    assert_equal 0, result.created
    assert_equal 1, result.updated
    assert_equal 0, result.failed

    existing.reload
    assert_equal "Updated Name", existing.name
    assert_equal "picked_up", existing.status
  end

  test "matches a route by name" do
    csv = csv_with_rows(
      "name" => "Routed Person",
      "email" => "routed.person@example.com",
      "street" => "456 Main St",
      "status" => "pending_pickup",
      "route" => routes(:one).name
    )

    result = import(csv)

    assert result.success?
    assert_equal routes(:one).id, Reservation.find_by(email: "routed.person@example.com").route_id
  end

  test "clears the route when the route name is not found" do
    csv = csv_with_rows(
      "name" => "Unrouted Person",
      "email" => "unrouted.person@example.com",
      "street" => "789 Main St",
      "route" => "Missing Route"
    )

    result = import(csv)

    assert result.success?
    assert_nil Reservation.find_by(email: "unrouted.person@example.com").route_id
  end

  test "skips duplicate emails in the backup" do
    csv = csv_with_rows(
      { "name" => "First Person", "email" => "duplicate@example.com", "street" => "1 Main St" },
      { "name" => "Second Person", "email" => "duplicate@example.com", "street" => "2 Main St" }
    )

    result = import(csv)

    assert result.success?
    assert_equal 1, result.created
    assert_equal 1, result.skipped
    assert_equal "First Person", Reservation.find_by(email: "duplicate@example.com").name
  end

  test "records invalid rows without aborting the restore" do
    csv = csv_with_rows(
      { "name" => "Good Person", "email" => "good@example.com", "street" => "1 Main St" },
      { "name" => "Bad Person", "email" => "bad@example.com", "street" => "2 Main St", "status" => "not_a_status" },
      { "name" => "Missing Email", "email" => "", "street" => "3 Main St" }
    )

    result = import(csv)

    assert result.success?
    assert_equal 1, result.created
    assert_equal 2, result.failed
    assert_equal 2, result.row_errors.size

    assert Reservation.find_by(email: "good@example.com")
    assert_not Reservation.find_by(email: "bad@example.com")
    assert Log.where(error_type: "ReservationCsvImport", severity: "error").exists?
  end

  test "does not send emails or write reservation activity logs" do
    csv = csv_with_rows(
      "name" => "Quiet Person",
      "email" => "quiet.person@example.com",
      "street" => "1 Main St",
      "status" => "picked_up"
    )

    ActionMailer::Base.deliveries.clear

    assert_no_difference -> { Log.of_type("reservation").count } do
      assert_no_enqueued_jobs only: ActionMailer::MailDeliveryJob do
        result = import(csv)
        assert result.success?
      end
    end

    assert_empty ActionMailer::Base.deliveries
  end

  test "rejects files missing the reservations export headers" do
    result = import("email,street\nsomeone@example.com,1 Main St\n")

    assert_not result.success?
    assert_includes result.error, "not a Tree Recycle reservations export"
    assert_includes result.error, "name"
  end

  test "rejects empty files" do
    result = import("")

    assert_not result.success?
    assert_equal "Please choose a reservations CSV file.", result.error
  end

  private

  def import(csv)
    ReservationCsvImport.new(csv: csv, filename: "reservations.csv").perform
  end

  def csv_with_rows(*rows)
    headers = rows.flat_map(&:keys).uniq
    CSV.generate do |csv|
      csv << headers
      rows.each { |row| csv << headers.map { |header| row[header] } }
    end
  end
end
