require "application_system_test_case"

class Admin::MarketingsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :admin, email_address: "admin@example.com", password: "password")
    visit admin_root_url
    fill_in "Email address", with: @admin.email_address
    fill_in "Password", with: @admin.password
    click_button "Sign in"
    sleep 0.25
  end

  test "visiting the index" do
    visit admin_marketing_index_url
  
    assert_selector "h1", text: "Marketing"
  end
end
