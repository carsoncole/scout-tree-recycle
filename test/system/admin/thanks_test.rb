require "application_system_test_case"

class Admin::ThanksTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:admin), true
  end

  test "creates, edits, and deletes a thank" do
    visit admin_thanks_url
    click_link "Add thank"

    fill_in "Content (optional)", with: "Thanks to the Riverside Garden Club."
    attach_file "Image", file_fixture("thanks.png")
    click_button "Create Thank"

    assert_text "Thank was successfully created."
    assert_text "Riverside Garden Club"

    all(:link, "Edit").first.click
    fill_in "Content (optional)", with: "Thanks to the Riverside Garden Club for their generous support."
    click_button "Update Thank"

    assert_text "Thank was successfully updated."
    assert_text "generous support"

    accept_confirm do
      all(:button, "Delete").first.click
    end

    assert_text "Thank was successfully deleted."
    assert_no_text "generous support"
  end
end
