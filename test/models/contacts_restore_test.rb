require "test_helper"
require "csv"

class ContactsRestoreTest < ActiveSupport::TestCase
  test "creates contacts from a backup csv" do
    csv = csv_with_rows(
      "name" => "Restored Person",
      "email" => "Restored.Person@Example.com",
      "street" => "123 Main St",
      "mobile" => "+11234567890",
      "marketing_1_email_sent_at" => "2026-01-01T10:00:00Z",
      "is_unsubscribed_from_marketing" => "true",
      "unsubscribed_at" => "2026-01-02T10:00:00Z",
      "created_at" => "2026-01-01T09:00:00Z",
      "updated_at" => "2026-01-01T09:05:00Z"
    )

    result = restore(csv)

    assert result.success?
    assert_equal 1, result.created
    assert_equal 0, result.updated

    contact = Contact.find_by(email: "restored.person@example.com")
    assert contact
    assert_equal "Restored Person", contact.name
    assert contact.is_unsubscribed_from_marketing?
    assert_equal Time.zone.parse("2026-01-02T10:00:00Z"), contact.unsubscribed_at
    assert_equal Time.zone.parse("2026-01-01T10:00:00Z"), contact.marketing_1_email_sent_at
    assert_equal Time.zone.parse("2026-01-01T09:00:00Z"), contact.created_at
  end

  test "updates an existing contact matched by normalized email" do
    existing = contacts(:full)
    csv = csv_with_rows(
      "name" => "Updated Name",
      "email" => existing.email.upcase,
      "street" => "456 Side St"
    )

    result = restore(csv)

    assert result.success?
    assert_equal 0, result.created
    assert_equal 1, result.updated

    existing.reload
    assert_equal "Updated Name", existing.name
    assert_equal "456 Side St", existing.street
  end

  test "skips duplicate emails in the backup" do
    csv = csv_with_rows(
      { "name" => "First Person", "email" => "duplicate@example.com" },
      { "name" => "Second Person", "email" => "duplicate@example.com" }
    )

    result = restore(csv)

    assert result.success?
    assert_equal 1, result.created
    assert_equal 1, result.skipped
    assert_equal "First Person", Contact.find_by(email: "duplicate@example.com").name
  end

  test "records invalid rows without aborting the restore" do
    csv = csv_with_rows(
      { "name" => "Good Person", "email" => "good.contact@example.com" },
      { "name" => "", "email" => "no.name@example.com" },
      { "name" => "Missing Email", "email" => "" }
    )

    result = restore(csv)

    assert result.success?
    assert_equal 1, result.created
    assert_equal 2, result.failed
    assert_equal 2, result.row_errors.size

    assert Contact.find_by(email: "good.contact@example.com")
    assert_not Contact.find_by(email: "no.name@example.com")
    assert Log.where(error_type: "ContactsRestore", severity: "error").exists?
  end

  test "ignores unknown columns" do
    csv = "id,name,email,unexpected\n999,Ignored Column,ignored.column@example.com,anything\n"

    result = restore(csv)

    assert result.success?
    assert_equal 1, result.created
    assert Contact.find_by(email: "ignored.column@example.com")
  end

  test "rejects files missing the required headers" do
    result = restore("name,street\nSomeone,1 Main St\n")

    assert_not result.success?
    assert_includes result.error, "not a Tree Recycle contacts export"
    assert_includes result.error, "email"
  end

  test "rejects empty files" do
    result = restore("")

    assert_not result.success?
    assert_equal "Please choose a contacts CSV file.", result.error
  end

  test "export writes the contact columns" do
    csv = ContactsRestore.export

    assert_equal Contact::EXPORT_FIELDS, CSV.parse(csv, headers: true).headers
    assert_includes csv, contacts(:full).email
  end

  private

  def restore(csv)
    ContactsRestore.new(csv: csv, filename: "contacts.csv").perform
  end

  def csv_with_rows(*rows)
    headers = rows.flat_map(&:keys).uniq
    CSV.generate do |csv|
      csv << headers
      rows.each { |row| csv << headers.map { |header| row[header] } }
    end
  end
end
