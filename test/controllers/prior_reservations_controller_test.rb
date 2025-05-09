require "test_helper"

class PriorReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get unsubscribe" do
    get unsubscribe_prior_reservation_url(prior_reservations(:one))
    assert_response :success
  end

  test "should unsubscribe prior reservation" do
    assert_difference "PriorReservation.count", -1 do
      delete prior_reservation_url(prior_reservations(:one))
    end
    assert_redirected_to root_path
    assert_equal "You have been successfully unsubscribed from our mailing list.", flash[:notice]
  end

  test "unsubscribing non-existent prior reservation should redirect to root" do
    get unsubscribe_prior_reservation_url(999)
    assert_redirected_to root_path
    assert_equal "Your email has already been unsubscribed.", flash[:alert]
  end

  test "unsubscribing prior reservation should destroy it" do 
    assert_difference "PriorReservation.count", -1 do
      delete prior_reservation_url(prior_reservations(:one))
    end
    assert_redirected_to root_path
    assert_equal "You have been successfully unsubscribed from our mailing list.", flash[:notice]
  end
end
