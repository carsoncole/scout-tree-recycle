require "test_helper"

class Mails::OutboundEmailTest < ActiveSupport::TestCase
  test "manual delivery stores the body and links the latest reservation and contact" do
    older = reservations(:picked_up_1)
    newer = reservations(:reservation_form_minimum)
    newer.update_columns(email: older.email, created_at: older.created_at + 1.day)

    mail = outbound_mail(
      handler: Mails::MessagesMailer,
      action: "compose",
      message_id: "manual-1@example.com",
      to: older.email,
      body: "Body text"
    )

    row = Mails::OutboundEmail.record_delivery!(mail)

    assert row.full_copy
    assert_includes row.body, "Body text"
    assert_equal "manual-1@example.com", row.message_id
    assert_equal "example@example.com", row.from_address
    assert_equal older.email, row.to_addresses
    assert_equal "Mails::MessagesMailer", row.mailer
    assert_equal "compose", row.action
    assert_equal "Manual email", row.type_label
    assert_equal newer.id, row.reservation_id
    assert_equal contacts(:name_and_email).id, row.contact_id
  end

  test "template delivery stores headers only" do
    mail = outbound_mail(
      handler: SettingsMailer,
      action: "test_email",
      message_id: "template-1@example.com",
      to: "person@example.com",
      body: "This is a test message that must not be stored"
    )

    row = Mails::OutboundEmail.record_delivery!(mail)

    assert_not row.full_copy
    assert_nil row.body
    assert_equal "SettingsMailer", row.mailer
    assert_equal "test_email", row.action
    assert_equal "Settings · Test email", row.type_label
    assert_equal "person@example.com", row.to_addresses
  end

  test "a duplicate message id is ignored" do
    mail = outbound_mail(
      handler: Mails::MessagesMailer,
      action: "compose",
      message_id: "duplicate-1@example.com",
      to: "person@example.com",
      body: "Once"
    )
    Mails::OutboundEmail.record_delivery!(mail)

    assert_no_difference -> { Mails::OutboundEmail.count } do
      assert Mails::OutboundEmail.record_delivery!(mail)
    end
  end

  test "a reply copies the received row links instead of matching the address again" do
    received = received_email_for(
      from: reservations(:picked_up_1).email,
      message_id: "inbound-parent@example.com"
    )
    received.update!(reservation: reservations(:picked_up_1), contact: nil)

    mail = outbound_mail(
      handler: Mails::MessagesMailer,
      action: "reply",
      message_id: "reply-1@example.com",
      to: reservations(:picked_up_1).email,
      body: "Thanks"
    )
    mail.in_reply_to = "<inbound-parent@example.com>"
    mail.instance_variable_set(:@mails_received_email_id, received.id)

    row = Mails::OutboundEmail.record_delivery!(mail)

    assert_equal reservations(:picked_up_1).id, row.reservation_id
    assert_nil row.contact_id
    assert_equal received.id, row.received_email_id
    assert_equal "inbound-parent@example.com", row.in_reply_to
    assert_equal "Reply", row.type_label
  end

  private

  def outbound_mail(handler:, action:, message_id:, to:, body:)
    mail = Mail.new do
      from "Example <example@example.com>"
      to to
      subject "Hello"
      body body
      message_id "<#{message_id}>"
    end
    mail.delivery_handler = handler
    mail.instance_variable_set(:@mails_action, action)
    mail
  end

  def received_email_for(from:, message_id:)
    mail = Mail.new do
      from from
      to "support@example.com"
      subject "Question"
      body "Hello"
      message_id "<#{message_id}>"
    end
    inbound = ActionMailbox::InboundEmail.create_and_extract_message_id!(mail.to_s, status: :processing)
    Mails::ReceivedEmail.record_inbound!(inbound)
  end
end
