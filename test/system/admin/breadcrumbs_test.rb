require "application_system_test_case"

class Admin::BreadcrumbsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "settings pages provide a breadcrumb trail" do
    visit admin_drivers_url

    within 'nav[aria-label="Breadcrumb"]' do
      assert_link "Settings", href: admin_settings_path
      assert_selector '[aria-current="page"]', text: "Drivers"
    end
  end
end
