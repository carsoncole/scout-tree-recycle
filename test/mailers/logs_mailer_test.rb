require "test_helper"

class LogsMailerTest < ActionMailer::TestCase
  test "includes a binary context without raising" do
    log = logs(:one)
    log.define_singleton_method(:context) { { "note" => "caf\xC3\xA9".b } }
    original_find = Log.method(:find)
    Log.define_singleton_method(:find) { |*| log }

    mail = LogsMailer.with(log_id: log.id, user_id: users(:admin).id).log_message_email

    assert_equal [ "one@example.com" ], mail.to
    assert_includes mail.text_part.body.decoded, "café"
  ensure
    Log.define_singleton_method(:find, original_find) if original_find
  end
end
