require "test_helper"

class DataMailerTest < ActionMailer::TestCase
  test "reservations_export_email delivers the csv export to the requested address" do
    Setting.instance.update!(email_from_address: "Troop 100 <troop100@example.com>")

    mail = DataMailer.reservations_export_email("qa@example.com")

    assert_equal [ "qa@example.com" ], mail.to
    assert_equal [ "troop100@example.com" ], mail.from
    assert_equal "Reservations CSV export from Troop 100", mail.subject
    assert_includes mail.html_part.body.decoded, "Reservations CSV export"
    assert_includes mail.text_part.body.decoded, "Sent by Troop 100"

    csv = mail.attachments.find { |part| part.filename.start_with?("reservations-") }
    assert csv
    assert_equal "text/csv", csv.mime_type
    assert_includes csv.body.decoded, "email"
    assert_includes csv.body.decoded, reservations(:pending_pickup_1).email
  end
end
