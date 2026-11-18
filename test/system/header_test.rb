require "application_system_test_case"

class HeaderTest < ApplicationSystemTestCase
  test "site header displays the organization name" do
    Setting.instance.update!(organization_name: "Troop 200", home_page_header: "Holiday Tree Recycle")

    visit root_url

    assert_selector ".site-wordmark", text: "Troop 200"
    assert_no_selector ".site-wordmark", text: "Holiday Tree Recycle"
  end
end
