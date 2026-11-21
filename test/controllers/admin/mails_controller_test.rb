require "test_helper"

class Admin::MailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    configure_email!
  end

  test "signed out visitors are sent to sign in" do
    get admin_mail_received_emails_url
    assert_redirected_to new_admin_session_url
  end

  test "a signed-in user can open the inbox" do
    sign_in(users(:user))
    get admin_mail_received_emails_url
    assert_response :success
    assert_match "No received emails.", response.body
    assert_select "#mail_unread_count .admin-nav-badge", count: 0
  end

  test "opening a message marks it read and the inbox checkbox sets both states" do
    sign_in
    received = receive_from("reader@example.com")

    get admin_mail_received_emails_url
    assert_response :success
    assert_select "#mail_unread_count .admin-nav-badge", text: "1"
    assert_select "tr.admin-mail-unread .admin-unread-dot"
    assert_select "input[type=checkbox][name=is_read][checked]", count: 0
    assert_select "button", text: "Mark unread", count: 0

    patch read_admin_mail_received_email_url(received), params: { is_read: "1" }, as: :turbo_stream
    assert_response :success
    assert received.reload.is_read
    assert_no_match "admin-mail-unread", response.body
    assert_match "checked", response.body

    get admin_mail_received_email_url(received)
    assert_response :success
    assert received.reload.is_read

    get admin_mail_received_emails_url
    assert_select "#mail_unread_count .admin-nav-badge", count: 0
    assert_select "tr.admin-mail-unread", count: 0
    assert_select "input[type=checkbox][name=is_read][checked]"

    patch read_admin_mail_received_email_url(received), as: :turbo_stream
    assert_response :success
    assert_not received.reload.is_read
    assert_match "admin-mail-unread", response.body
    assert_match "mail_unread_count", response.body

    received.mark_read!
    patch read_admin_mail_received_email_url(received), params: { is_read: "0" }
    assert_redirected_to admin_mail_received_emails_url
    assert_not received.reload.is_read
    assert_equal "Marked as unread.", flash[:notice]

    patch read_admin_mail_received_email_url(received), params: { is_read: "1" }
    assert_redirected_to admin_mail_received_emails_url
    assert received.reload.is_read
    assert_equal "Marked as read.", flash[:notice]
  end

  test "compose stores a full outbox row linked to the reservation" do
    sign_in
    reservation = reservations(:reservation_form_minimum)

    assert_difference -> { Mails::OutboundEmail.count }, 1 do
      with_test_delivery do
        post admin_mail_outbound_emails_url, params: {
          to: reservation.email,
          subject: "Pickup update",
          body: "We will be there Saturday.",
          file: "ignored.txt"
        }
      end
    end

    outbound = Mails::OutboundEmail.order(:id).last
    assert_redirected_to admin_mail_outbound_email_url(outbound)
    assert_includes outbound.body, "We will be there Saturday."
    assert outbound.full_copy
    assert_equal reservation.id, outbound.reservation_id
    assert_empty ActionMailer::Base.deliveries.last.attachments
  end

  test "compose refuses incomplete messages" do
    sign_in

    assert_no_difference -> { Mails::OutboundEmail.count } do
      with_test_delivery do
        post admin_mail_outbound_emails_url, params: { to: "not-an-email", subject: "", body: "" }
      end
    end

    assert_response :unprocessable_entity
    assert_match "Enter a recipient, subject, and message.", response.body
  end

  test "a reply stores the body and threading headers" do
    sign_in
    received = receive_from(reservations(:reservation_form_minimum).email)

    assert_difference -> { Mails::OutboundEmail.count }, 1 do
      with_test_delivery do
        post admin_mail_received_email_replies_url(received), params: { body: "Glad to help." }
      end
    end

    outbound = Mails::OutboundEmail.order(:id).last
    assert_redirected_to admin_mail_outbound_email_url(outbound)
    assert_includes outbound.body, "Glad to help."
    assert_equal received.id, outbound.received_email_id
    assert_equal received.message_id, outbound.in_reply_to
    assert_includes outbound.references_header, received.message_id
    assert_empty ActionMailer::Base.deliveries.last.attachments
  end

  test "update sets and clears reservation and contact links" do
    sign_in
    received = receive_from("stranger@example.com")

    patch admin_mail_received_email_url(received), params: {
      reservation_email: reservations(:reservation_form_minimum).email,
      contact_email: contacts(:full).email,
      reservation_id: reservations(:picked_up_1).id,
      contact_id: contacts(:name_and_email).id
    }

    received.reload
    assert_redirected_to admin_mail_received_email_url(received)
    assert_equal reservations(:reservation_form_minimum).id, received.reservation_id
    assert_equal contacts(:full).id, received.contact_id

    patch admin_mail_received_email_url(received), params: {
      reservation_email: "",
      contact_email: ""
    }
    received.reload
    assert_nil received.reservation_id
    assert_nil received.contact_id

    patch admin_mail_received_email_url(received), params: {
      reservation_email: "nobody@example.com",
      contact_email: contacts(:full).email
    }
    received.reload
    assert_nil received.reservation_id
    assert_equal contacts(:full).id, received.contact_id
    assert_match "No reservation matches nobody@example.com.", flash[:alert]
  end

  test "the outbox does not render a template body" do
    sign_in
    with_test_delivery do
      SettingsMailer.test_email("person@example.com").deliver_now
    end
    outbound = Mails::OutboundEmail.order(:id).last

    get admin_mail_outbound_email_url(outbound)
    assert_response :success
    assert_match "This send was recorded without the message body.", response.body
    assert_no_match(/This is a test message/, response.body)
    assert_no_match(/Email settings are working/, response.body)

    get admin_mail_received_emails_url
    assert_response :success
    assert_no_match(/This is a test message/, response.body)
    assert_no_match(/Email settings are working/, response.body)
  end

  test "destroy removes a received email" do
    sign_in
    received = receive_from("delete-me@example.com")

    assert_difference -> { Mails::ReceivedEmail.count }, -1 do
      delete admin_mail_received_email_url(received)
    end

    assert_redirected_to admin_mail_received_emails_url
    assert_equal "Email deleted.", flash[:notice]
  end

  test "destroy removes an outbound email" do
    sign_in
    with_test_delivery do
      SettingsMailer.test_email("person@example.com").deliver_now
    end
    outbound = Mails::OutboundEmail.order(:id).last

    assert_difference -> { Mails::OutboundEmail.count }, -1 do
      delete admin_mail_outbound_email_url(outbound)
    end

    assert_redirected_to admin_mail_outbound_emails_url
    assert_equal "Email deleted.", flash[:notice]
  end

  private

  def receive_from(from)
    mail = Mail.new do
      from from
      to "support@example.com"
      subject "Question"
      body "Hello there"
    end
    inbound = ActionMailbox::InboundEmail.create_and_extract_message_id!(mail.to_s, status: :processing)
    ApplicationMailbox.route inbound
    Mails::ReceivedEmail.find_by!(inbound_email: inbound)
  end
end
