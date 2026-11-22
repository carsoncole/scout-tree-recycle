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
    assert_includes html, "Troop 100 Tree Recycle"
    assert_includes html, "Arial, Helvetica, sans-serif"
    assert_no_match(/<img/i, html)
    assert_no_match(/localhost/, html)
  end

  test "test_email does not attach any images" do
    mail = SettingsMailer.test_email("qa@example.com")

    assert_empty mail.attachments
  end
end
