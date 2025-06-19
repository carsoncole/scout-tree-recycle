require "test_helper"

class Admin::PriorReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get destroy" do
    sign_in
    delete admin_prior_reservation_url(prior_reservations(:full))
    assert_redirected_to admin_marketing_index_path
    assert_equal "Prior reservation was successfully deleted.", flash[:notice]
  end
end
