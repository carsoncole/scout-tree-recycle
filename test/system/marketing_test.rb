require "application_system_test_case"

class MarketingTest < ApplicationSystemTestCase
  test "registering for a tree pickup from a marketing email with a prior reservation that has all fields" do
    visit root_url(prior_reservation_id: prior_reservations(:full).id)
    
    # Check that form fields are pre-populated with the correct values
    assert_field "Name", with: "Susan Banks"
    assert_field "Street", with: "123 Main St"
    assert_field "Email", with: "trip.wilson@example.com"
    assert_field "Mobile (Recommended)", with: "+11234567890"
  end

  test "registering for a tree pickup from a marketing email with a prior reservation that has no mobile" do
    visit root_url(prior_reservation_id: prior_reservations(:no_mobile).id)
    
    # Check that form fields are pre-populated with the correct values
    assert_field "Name", with: "Trellis Travic"
    assert_field "Street", with: "123 Main St"
    assert_field "Email", with: "trellis.travic@example.com"
    assert_field "Mobile (Recommended)", with: ""
  end
end