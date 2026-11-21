require "test_helper"

class Mails::ReceivedEmailTest < ActiveSupport::TestCase
  test "a direct message links the contact and the latest reservation" do
    older = reservations(:picked_up_1)
    newer = reservations(:reservation_form_minimum)
    newer.update_columns(email: older.email, created_at: older.created_at + 1.day)

    received = receive_from(older.email, message_id: "direct-1@example.com")

    assert_equal contacts(:name_and_email).id, received.contact_id
    assert_equal newer.id, received.reservation_id
    assert_equal "Received", received.type_label
    assert_not_includes Mails::ReceivedEmail.column_names, "body"
  end

  test "a reply copies the outbound links instead of a newer reservation" do
    older = reservations(:picked_up_1)
    newer = reservations(:reservation_form_minimum)
    newer.update_columns(email: older.email, created_at: older.created_at + 1.day)
    Mails::OutboundEmail.create!(
      message_id: "sent-parent@example.com",
      from_address: "example@example.com",
      to_addresses: older.email,
      subject: "Earlier note",
      sent_at: Time.current,
      full_copy: true,
      body: "Earlier",
      reservation: older,
      contact: nil
    )

    received = receive_from(
      older.email,
      message_id: "inbound-reply@example.com",
      in_reply_to: "<sent-parent@example.com>"
    )

    assert_equal older.id, received.reservation_id
    assert_nil received.contact_id
    assert_equal "Reply", received.type_label
    assert_equal "sent-parent@example.com", received.in_reply_to
  end

  test "a reply with no parent links falls back to the address" do
    older = reservations(:picked_up_1)
    Mails::OutboundEmail.create!(
      message_id: "unlinked-parent@example.com",
      from_address: "example@example.com",
      to_addresses: older.email,
      subject: "Earlier note",
      sent_at: Time.current,
      full_copy: false,
      reservation: nil,
      contact: nil
    )

    received = receive_from(
      older.email,
      message_id: "fallback-reply@example.com",
      in_reply_to: "<unlinked-parent@example.com>"
    )

    assert_equal older.id, received.reservation_id
    assert_equal contacts(:name_and_email).id, received.contact_id
  end

  test "recording the same inbound email twice keeps one row" do
    received = receive_from("trip.wilson@example.com", message_id: "once@example.com")

    assert_no_difference -> { Mails::ReceivedEmail.count } do
      again = Mails::ReceivedEmail.record_inbound!(received.inbound_email)
      assert_equal received.id, again.id
    end
  end

  test "html-only mail is shown as text" do
    mail = Mail.new do
      from "trip.wilson@example.com"
      to "support@example.com"
      subject "Html"
      message_id "<html-only@example.com>"
      content_type "text/html; charset=UTF-8"
      body "<p>Hello <script>alert(1)</script>there</p>"
    end
    inbound = ActionMailbox::InboundEmail.create_and_extract_message_id!(mail.to_s, status: :processing)
    received = Mails::ReceivedEmail.record_inbound!(inbound)

    assert_includes received.display_body, "Hello"
    assert_includes received.display_body, "there"
    assert_not_includes received.display_body, "<script>"
    assert_not_includes received.display_body, "<p>"
  end

  private

  def receive_from(from, message_id:, in_reply_to: nil)
    mail = Mail.new do
      from from
      to "support@example.com"
      subject "Question"
      body "Hello there"
      message_id "<#{message_id}>"
    end
    mail.in_reply_to = in_reply_to if in_reply_to
    inbound = ActionMailbox::InboundEmail.create_and_extract_message_id!(mail.to_s, status: :processing)
    Mails::ReceivedEmail.record_inbound!(inbound)
  end
end
