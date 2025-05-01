require "test_helper"

class Admin::PriorReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get destroy" do
    get admin_prior_reservations_destroy_url
    assert_response :success
  end
end
