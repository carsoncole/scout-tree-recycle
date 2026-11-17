require "test_helper"

class Admin::ReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_reservations_url
    assert_response :success
  end

  test "should get index with closed reservations" do
    Setting.instance.update(is_reservations_open: false)
    sign_in
    get admin_reservations_url
    assert_equal "Reservations are CLOSED.", flash[:alert]
  end

  test "should get show" do
    sign_in
    get admin_reservation_url(reservations(:pending_pickup_1))
    assert_response :success
  end

  test "should get edit" do
    sign_in
    get edit_admin_reservation_url(reservations(:pending_pickup_1))
    assert_response :success
  end

  test "should get update" do
    sign_in
    patch admin_reservation_url(reservations(:pending_pickup_1)), params: { reservation: { name: "New Name" } }
    assert_redirected_to edit_admin_reservation_url(reservations(:pending_pickup_1))
    assert_equal "Reservation was successfully updated.", flash[:notice]
  end

  test "should get destroy" do
    sign_in
    delete admin_reservation_url(reservations(:pending_pickup_1))
    assert_redirected_to admin_reservations_url
    assert_equal "Reservation was successfully deleted.", flash[:notice]
  end

  test "should show send and resend buttons for each email type" do
    sign_in
    reservation = reservations(:pending_pickup_1)
    get admin_reservation_url(reservation)

    assert_select "form[action=?]", resend_email_admin_reservation_path(reservation), count: 3
    assert_select "input[name=kind][value=confirmation]"
    assert_select "input[name=kind][value=cancellation]"
    assert_select "input[name=kind][value=missing_tree]"
    assert_select "button[data-turbo-confirm]" do |buttons|
      assert buttons.any? { |button| button["data-turbo-confirm"].include?("was already sent") }
    end
  end

  test "should resend the confirmation email" do
    sign_in
    Setting.instance.update(is_emailing_enabled: true)
    reservation = reservations(:pending_pickup_1)

    assert_enqueued_emails 1 do
      post resend_email_admin_reservation_url(reservation), params: { kind: "confirmation" }
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Confirmation email was queued for delivery to #{reservation.email}.", flash[:notice]
  end

  test "should resend the cancellation email" do
    sign_in
    Setting.instance.update(is_emailing_enabled: true)
    reservation = reservations(:cancelled_1)

    assert_enqueued_emails 1 do
      post resend_email_admin_reservation_url(reservation), params: { kind: "cancellation" }
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Cancellation email was queued for delivery to #{reservation.email}.", flash[:notice]
  end

  test "should resend the missing tree email" do
    sign_in
    Setting.instance.update(is_emailing_enabled: true)
    reservation = reservations(:missing_1)

    assert_enqueued_emails 1 do
      post resend_email_admin_reservation_url(reservation), params: { kind: "missing_tree" }
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Missing tree email was queued for delivery to #{reservation.email}.", flash[:notice]
  end

  test "should not resend an unknown email type" do
    sign_in
    Setting.instance.update(is_emailing_enabled: true)
    reservation = reservations(:pending_pickup_1)

    assert_no_enqueued_emails do
      post resend_email_admin_reservation_url(reservation), params: { kind: "bogus" }
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Unknown email type.", flash[:alert]
  end

  test "should not resend an email when emailing is disabled" do
    sign_in
    Setting.instance.update(is_emailing_enabled: false)
    reservation = reservations(:pending_pickup_1)

    assert_no_enqueued_emails do
      post resend_email_admin_reservation_url(reservation), params: { kind: "confirmation" }
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Emailing is disabled. Enable it in Settings before sending emails.", flash[:alert]
  end
end
