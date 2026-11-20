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
    assert_includes body, "Troop 100 Tree Recycle"
    assert_not_includes body, "located at"
    assert_includes body, "expires in 7 days"
    assert_match %r{/account_setups/[^"'\s<]+/edit}, body

    html = mail.html_part.body.decoded
    assert_includes html, "max-width: 600px"
    assert_includes html, "word-break: break-all"
    assert_no_match(/width="600"/, html)
    assert_includes html, '<meta name="viewport" content="width=device-width, initial-scale=1.0" />'
    assert_equal 1, html.scan(/<html/i).size
  end

  test "account_created includes the site url when one is configured" do
    Setting.instance.update!(site_url: "https://trees.example.com")
    user = users(:user)
    mail = UsersMailer.account_created(user)

    body = [ mail.text_part, mail.html_part ].compact.map { |part| part.body.decoded }.join("\n")
    assert_includes body, "Troop 100 Tree Recycle, located at https://trees.example.com"

    html = mail.html_part.body.decoded
    assert_includes html, '<a href="https://trees.example.com" style="color: #4c6a57; text-decoration: none;">https://trees.example.com</a>'
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
