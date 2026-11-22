require "test_helper"

class AdminMailerTest < ActionMailer::TestCase
  test "admin mailers inherit from AdminMailer" do
    assert AdminMailer < ApplicationMailer
    assert LogsMailer < AdminMailer
    assert PasswordsMailer < AdminMailer
    assert SettingsMailer < AdminMailer
    assert UsersMailer < AdminMailer
  end

  test "every admin email shows the event name without images or date details" do
    admin_mails.each do |mailer_name, mail|
      html = mail.html_part.body.decoded

      assert_includes html, "Troop 100 Tree Recycle", "#{mailer_name} is missing the event name header"
      assert_includes html, "&mdash; Troop 100 Tree Recycle", "#{mailer_name} is missing the event name footer"
      assert_no_match(/<img/i, html, "#{mailer_name} should not include images")
      assert_no_match(/2099/, html, "#{mailer_name} should not include event date or time details")
    end
  end

  test "every admin email uses the shared font stack" do
    admin_mails.each do |mailer_name, mail|
      html = mail.html_part.body.decoded

      assert_includes html, "Arial, Helvetica, sans-serif", "#{mailer_name} is missing the shared font stack"
      assert_equal 1, html.scan(/<html/i).size, "#{mailer_name} should render a single document through the layout"
      assert_includes html, "max-width: 600px", "#{mailer_name} is missing the shared card width"
    end
  end

  test "text parts include the event name header and footer" do
    admin_mails.each do |mailer_name, mail|
      text = mail.text_part.body.decoded

      assert text.start_with?("Troop 100 Tree Recycle"), "#{mailer_name} text part is missing the event name header"
      assert_includes text, "--\nTroop 100 Tree Recycle", "#{mailer_name} text part is missing the event name footer"
    end
  end

  private

  def admin_mails
    {
      "LogsMailer" => LogsMailer.with(log_id: logs(:one).id, user_id: users(:admin).id).log_message_email,
      "PasswordsMailer" => PasswordsMailer.reset(users(:admin)),
      "SettingsMailer" => SettingsMailer.test_email("qa@example.com"),
      "UsersMailer" => UsersMailer.account_created(users(:user))
    }
  end
end
