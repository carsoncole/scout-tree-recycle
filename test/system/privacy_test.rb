require "application_system_test_case"

class PrivaciesTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit privacy_url
  
    assert_selector "h1", text: "Privacy Policy"

    click_link "Back to Home"
    assert_text "Make a Reservation"
  end
end
