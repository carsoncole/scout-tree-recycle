require "test_helper"

class SettingsMailerTest < ActionMailer::TestCase
  test "test_email sends to the requested address" do
    Setting.instance.update!(email_from_address: "Troop 100 <troop100@example.com>")

    mail = SettingsMailer.test_email("qa@example.com")

    assert_equal [ "qa@example.com" ], mail.to
    assert_equal [ "troop100@example.com" ], mail.from
    assert_equal "Test email from Troop 100", mail.subject
    assert_includes mail.body.encoded, "Email settings are working"
    assert_includes mail.body.encoded, "Troop 100"

    html = mail.html_part.body.decoded
    assert_match(/src="cid:[^"]+"/, html)
    assert_no_match(/localhost/, html)
    logo = mail.attachments.find { |part| part.filename == ApplicationMailer::LOGO_FILENAME }
    assert logo&.inline?
  end
end
