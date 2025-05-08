require "application_system_test_case"

class Admin::MarketingsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the index" do
    visit admin_marketing_index_url

    assert_selector "h1", text: "Marketing"
  end
end
