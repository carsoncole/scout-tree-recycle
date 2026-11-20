require "test_helper"

class UsersMailerTest < ActionMailer::TestCase
  test "account_created sends a password setup link to the new user" do
    user = users(:user)
    mail = UsersMailer.account_created(user)

    assert_equal [ user.email ], mail.to
    assert_equal [ "example@example.com" ], mail.from
    assert_equal "Set up your Troop 100 account", mail.subject

    body = [ mail.text_part, mail.html_part ].compact.map { |part| part.body.decoded }.join("\n")
    assert_includes body, user.email
    assert_includes body, "Troop 100"
    assert_includes body, "expires in 7 days"
    assert_match %r{/account_setups/[^"'\s<]+/edit}, body
  end

  test "delivery is recorded in the email log" do
    user = users(:user)

    assert_difference -> { Log.of_type("email").count }, 1 do
      UsersMailer.account_created(user).deliver_now
    end

    log = Log.of_type("email").last
    assert_equal "Account setup email sent to #{user.email}: Set up your Troop 100 account", log.message
    assert_equal user.email, log.context["to"]
    assert_equal "info", log.severity
  end
end
