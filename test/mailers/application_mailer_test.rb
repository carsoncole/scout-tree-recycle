require "test_helper"

class ApplicationMailerTest < ActionMailer::TestCase
  setup do
    @original_default_url_options = ActionMailer::Base.default_url_options
    @original_default_params = PasswordsMailer.default_params
  end

  teardown do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
    ActionMailer::Base.default_url_options = @original_default_url_options
    PasswordsMailer.default_params = @original_default_params
  end

  test "uses configured sender and smtp settings" do
    Setting.instance.update(
      email_from_address: "Troop 100 <troop100@example.com>",
      smtp_address: "smtp.example.com",
      smtp_port: 587,
      smtp_user_name: "smtp-user",
      smtp_password: "smtp-password",
      smtp_authentication: "plain",
      smtp_encryption: "starttls"
    )

    email = PasswordsMailer.reset(users(:admin))

    assert_equal [ "troop100@example.com" ], email.from
    assert_equal :smtp, ActionMailer::Base.delivery_method
    assert_equal "smtp.example.com", ActionMailer::Base.smtp_settings[:address]
    assert_equal 587, ActionMailer::Base.smtp_settings[:port]
    assert_equal "smtp-user", ActionMailer::Base.smtp_settings[:user_name]
  end

  test "uses configured site url for links" do
    Setting.instance.update(site_url: "https://trees.example.org:8443")

    email = PasswordsMailer.reset(users(:admin))

    assert_includes email.body.encoded, "https://trees.example.org:8443"

    options = ActionMailer::Base.default_url_options
    assert_equal "trees.example.org", options[:host]
    assert_equal "https", options[:protocol]
    assert_equal 8443, options[:port]
  end
end
