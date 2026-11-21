require "test_helper"

class Mails::InboundSourceTest < ActiveSupport::TestCase
  test "plain text is returned unchanged" do
    source = Mail.new do
      from "a@example.com"
      to "b@example.com"
      subject "Hi"
      body "Hello"
    end.to_s

    assert_equal source, Mails::InboundSource.strip(source)
  end

  test "attachments and inline images are removed" do
    mail = Mail.new
    mail.from = "a@example.com"
    mail.to = "b@example.com"
    mail.subject = "Hi"
    mail.text_part = Mail::Part.new { body "Hello there" }
    mail.html_part = Mail::Part.new do
      content_type "text/html; charset=UTF-8"
      body "<p>Hello there</p>"
    end
    mail.add_file filename: "note.txt", content: "secret attachment bytes"
    mail.attachments.inline["logo.png"] = "PNGDATA-secret"

    stripped = Mails::InboundSource.strip(mail.to_s)

    assert_includes stripped, "Hello there"
    assert_not_includes stripped, "secret attachment bytes"
    assert_not_includes stripped, "PNGDATA-secret"
    assert_empty Mail.new(stripped).attachments
  end

  test "a message that is only an attachment keeps no file bytes" do
    mail = Mail.new
    mail.from = "a@example.com"
    mail.to = "b@example.com"
    mail.subject = "File"
    mail.add_file filename: "note.txt", content: "secret attachment bytes"

    stripped = Mails::InboundSource.strip(mail.to_s)

    assert_not_includes stripped, "secret attachment bytes"
  end

  test "an unparseable source is returned as-is" do
    source = "not a mail message"
    original = Mail.method(:new)
    Mail.define_singleton_method(:new) { |*| raise "unparseable" }

    assert_equal source, Mails::InboundSource.strip(source)
  ensure
    Mail.define_singleton_method(:new, original) if original
  end
end
