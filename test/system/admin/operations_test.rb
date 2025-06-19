require "application_system_test_case"

class Admin::OperationsTest < ApplicationSystemTestCase
  test "migration as an admin user" do
    sign_in_as(users(:admin), true)
    visit admin_settings_url
    accept_confirm do
      click_button "Migrate"
    end

    visit admin_marketing_index_url
    assert_equal 13, page.all("table tbody tr").count

    visit admin_reservations_url
    assert_equal 0, page.all("table tbody tr").count
  end

  test "migration as a non-admin user" do
    sign_in_as(users(:user), true)
    visit admin_settings_url

    accept_confirm do
      click_button "Migrate"
    end
    assert_text "You are not authorized to perform this operation"
  end
end
