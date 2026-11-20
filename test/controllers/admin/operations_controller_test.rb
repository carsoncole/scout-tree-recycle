require "test_helper"

class Admin::OperationsControllerTest < ActionDispatch::IntegrationTest
  test "show explains closing the event and includes retention" do
    sign_in

    get admin_close_event_path

    assert_response :success
    assert_match "What closing the event does", response.body
    assert_match "Retention (Months)", response.body
    assert_match "Type CLOSE to accept", response.body
    assert_match "Confirm", response.body
  end

  test "non-admin can view the explanation without the acceptance form" do
    sign_in users(:user)

    get admin_close_event_path

    assert_response :success
    assert_match "What closing the event does", response.body
    assert_match "Retention (Months)", response.body
    assert_no_match "Type CLOSE to accept", response.body
  end

  test "create requires acceptance" do
    sign_in

    assert_no_difference -> { Reservation.count } do
      post admin_close_event_path, params: { confirmation: "no" }
    end

    assert_redirected_to admin_close_event_path
    assert_equal "Type CLOSE to accept closing this event.", flash[:alert]
  end

  test "create closes the event" do
    sign_in
    copied_email = reservations(:pending_pickup_1).email
    unfinished_email = reservations(:donation_1).email

    post admin_close_event_path, params: { confirmation: "close" }

    assert_redirected_to admin_settings_section_path("system")
    assert_equal "Event closed. Reservations were copied into contacts and cleared for the next event.", flash[:notice]
    assert_equal 0, Reservation.count
    assert Contact.find_by(email: copied_email)
    assert_not Contact.find_by(email: unfinished_email)
  end

  test "non-admin cannot close the event" do
    sign_in users(:user)

    assert_no_difference -> { Reservation.count } do
      post admin_close_event_path, params: { confirmation: "CLOSE" }
    end

    assert_redirected_to admin_close_event_path
    assert_equal "You are not authorized to close the event.", flash[:alert]
  end
end
