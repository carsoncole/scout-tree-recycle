require "test_helper"

class DataMailerTest < ActionMailer::TestCase
  test "backup_email delivers the zip backup to the requested address" do
    Setting.instance.update!(email_from_address: "Troop 100 <troop100@example.com>")

    mail = DataMailer.backup_email("qa@example.com", datasets: %w[reservations settings])

    assert_equal [ "qa@example.com" ], mail.to
    assert_equal [ "troop100@example.com" ], mail.from
    assert_equal "Data backup from Troop 100", mail.subject
    assert_includes mail.html_part.body.decoded, "Data backup"
    assert_includes mail.text_part.body.decoded, "Store this file securely"

    attachment = mail.attachments.find { |part| part.filename.end_with?(".zip") }
    assert attachment
    assert_equal "application/zip", attachment.mime_type

    files = zip_entries(attachment.body.decoded)
    assert_includes files.keys, "settings.json"
    assert_includes files.keys, "reservations.csv"
    assert_includes files.fetch("reservations.csv"), reservations(:pending_pickup_1).email
  end

  test "backup_email can send only the selected dataset" do
    mail = DataMailer.backup_email("qa@example.com", datasets: [ "settings" ])

    attachment = mail.attachments.find { |part| part.filename.end_with?(".zip") }
    files = zip_entries(attachment.body.decoded)

    assert_includes files.keys, "settings.json"
    assert_not_includes files.keys, "reservations.csv"
  end

  private

  def zip_entries(body)
    entries = {}
    Zip::File.open_buffer(StringIO.new(body)) do |zip|
      zip.each { |entry| entries[entry.name] = entry.get_input_stream.read }
    end
    entries
  end
end
