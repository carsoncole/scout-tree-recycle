require "test_helper"

class Mails::MessagesMailerTest < ActionMailer::TestCase
  setup do
    ActionMailer::Base.delivery_method = :test
  end

  test "a reply sets threading headers and has no attachments" do
    received = receive_message(
      message_id: "inbound-thread@example.com",
      references: "<older-thread@example.com>",
      reply_to: "reply-here@example.com",
      subject: "Pickup question"
    )

    message = Mails::MessagesMailer.reply(received, body: "We can pick it up Saturday.").message

    assert_equal [ "reply-here@example.com" ], message.to
    assert_equal "Re: Pickup question", message.subject
    assert_includes message["In-Reply-To"].to_s, "inbound-thread@example.com"
    assert_includes message["References"].to_s, "older-thread@example.com"
    assert_includes message["References"].to_s, "inbound-thread@example.com"
    assert_empty message.attachments
    assert_equal "text/plain", message.mime_type
  end

  test "a subject that already starts with Re is left alone" do
    received = receive_message(message_id: "already-re@example.com", subject: "Re: Pickup question")

    message = Mails::MessagesMailer.reply(received, body: "Sounds good.").message

    assert_equal "Re: Pickup question", message.subject
  end

  test "a template delivery records a header-only outbox row" do
    assert_difference -> { Mails::OutboundEmail.count }, 1 do
      SettingsMailer.test_email("person@example.com").deliver_now
    end

    row = Mails::OutboundEmail.order(:id).last
    assert_nil row.body
    assert_not row.full_copy
    assert_equal "SettingsMailer", row.mailer
    assert_equal "test_email", row.action
    assert_equal "person@example.com", row.to_addresses
    assert row.message_id.present?
    assert row.sent_at.present?
  end

  test "an observer failure does not raise out of delivery" do
    before = Mails::OutboundEmail.count
    original = Mails::OutboundEmail.method(:record_delivery!)
    Mails::OutboundEmail.define_singleton_method(:record_delivery!) { |*| raise "archive down" }

    assert_nothing_raised do
      SettingsMailer.test_email("person@example.com").deliver_now
    end

    assert_equal before, Mails::OutboundEmail.count
    assert_equal 1, ActionMailer::Base.deliveries.size
  ensure
    Mails::OutboundEmail.define_singleton_method(:record_delivery!, original) if original
  end

  private

  def receive_message(message_id:, subject: "Pickup question", references: nil, reply_to: nil)
    mail = Mail.new do
      from "neighbor@example.com"
      to "support@example.com"
      subject subject
      body "When are you coming?"
      message_id "<#{message_id}>"
    end
    mail.references = references if references
    mail.reply_to = reply_to if reply_to
    inbound = ActionMailbox::InboundEmail.create_and_extract_message_id!(mail.to_s, status: :processing)
    Mails::ReceivedEmail.record_inbound!(inbound)
  end
end
