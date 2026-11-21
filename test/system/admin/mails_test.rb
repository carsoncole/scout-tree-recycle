require "application_system_test_case"

class Admin::MailsTest < ApplicationSystemTestCase
  setup do
    configure_email!
  end

  test "unread mail is emphasized until it is read and the checkbox sets both states" do
    sign_in_as(users(:admin), true)
    receive_from("form.minimum@example.com")

    visit admin_mail_received_emails_path
    assert_selector "tr.admin-mail-unread", text: "Where should I leave the tree?"
    within "#mail_unread_count" do
      assert_text "1"
    end
    within "tr", text: "Where should I leave the tree?" do
      assert_unchecked_field "Read"
      check "Read"
    end

    assert_no_selector "tr.admin-mail-unread"
    within "#mail_unread_count" do
      assert_no_text "1"
    end
    within "tr", text: "Where should I leave the tree?" do
      assert_checked_field "Read"
      uncheck "Read"
    end

    assert_selector "tr.admin-mail-unread", text: "Where should I leave the tree?"
    within "#mail_unread_count" do
      assert_text "1"
    end

    click_link "Where should I leave the tree?"
    assert_text "Back to inbox"

    visit admin_mail_received_emails_path
    assert_no_selector "tr.admin-mail-unread"
    within "tr", text: "Where should I leave the tree?" do
      assert_checked_field "Read"
    end
    within "#mail_unread_count" do
      assert_no_text "1"
    end
  end

  test "inbox rows link the reservation and contact when they are present" do
    reservation = reservations(:picked_up_1)
    contact = contacts(:name_and_email)
    sign_in_as(users(:admin), true)
    receive_from(reservation.email)
    receive_from("stranger@example.com")

    visit admin_mail_received_emails_path
    within "tr", text: reservation.email do
      assert_link "Reservation", href: admin_reservation_path(reservation)
      assert_link "Contact", href: admin_contact_path(contact)
      click_link "Reservation"
    end
    assert_current_path admin_reservation_path(reservation)

    visit admin_mail_received_emails_path
    within "tr", text: reservation.email do
      click_link "Contact"
    end
    assert_current_path admin_contact_path(contact)

    visit admin_mail_received_emails_path
    within "tr", text: "stranger@example.com" do
      assert_no_link "Reservation"
      assert_no_link "Contact"
    end
  end

  test "the inbox is empty until a message arrives" do
    sign_in_as(users(:admin), true)
    visit admin_mail_received_emails_path

    assert_selector "h1", text: "Mail"
    assert_text "No received emails."
  end

  test "composing and replying shows the mail on the reservation and contact" do
    reservation = reservations(:picked_up_1)
    contact = contacts(:name_and_email)

    with_test_delivery do
      sign_in_as(users(:admin), true)

      visit admin_reservation_path(reservation)
      click_link "New email"
      assert_field "To", with: reservation.email

      fill_in "Subject", with: "Pickup update"
      fill_in "Message", with: "We will be there Saturday."
      click_button "Send email"

      assert_text "Email sent."
      assert_text "Pickup update"
      assert_text "We will be there Saturday."

      visit admin_reservation_path(reservation)
      assert_text "Pickup update"
      visit admin_contact_path(contact)
      assert_text "Pickup update"

      visit admin_mail_outbound_emails_path
      assert_text "Pickup update"
      assert_text "Manual email"

      received = receive_from(reservation.email)
      visit admin_mail_received_email_path(received)
      assert_text "Where should I leave the tree?"

      fill_in "Reply", with: "Leave it by the curb."
      click_button "Send reply"

      assert_text "Reply sent."
      assert_text "Leave it by the curb."
      assert_text "Re: Where should I leave the tree?"
    end
  end

  private

  def receive_from(from)
    mail = Mail.new do
      from from
      to "support@example.com"
      subject "Where should I leave the tree?"
      body "Where should I leave the tree?"
    end
    inbound = ActionMailbox::InboundEmail.create_and_extract_message_id!(mail.to_s, status: :processing)
    ApplicationMailbox.route inbound
    Mails::ReceivedEmail.find_by!(inbound_email: inbound)
  end
end
