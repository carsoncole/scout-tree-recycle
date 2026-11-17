require "application_system_test_case"

class Admin::ThanksTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:admin), true
  end

  test "updates the thank you message shown on public pages" do
    visit admin_thanks_url

    within "section", text: "Thank You Message" do
      fill_in "Message", with: "Custom thanks to our community."
      click_on "Save Thank You Message"
    end

    assert_text "Settings were successfully updated."
    assert_field "Message", with: "Custom thanks to our community."

    visit about_url
    assert_text "Custom thanks to our community."

    visit thanks_url
    assert_text "Custom thanks to our community."

    visit admin_thanks_url
    within "section", text: "Thank You Message" do
      click_on "Restore default text"
    end

    assert_field "Message", with: Setting::DEFAULT_THANK_YOU_MESSAGE

    visit about_url
    assert_text Setting::DEFAULT_THANK_YOU_MESSAGE
    assert_no_text "Custom thanks to our community."
  end

  test "clearing the thank you message hides it from public pages" do
    visit admin_thanks_url

    within "section", text: "Thank You Message" do
      fill_in "Message", with: ""
      click_on "Save Thank You Message"
    end

    assert_field "Message", with: ""

    visit about_url
    assert_no_selector "h3", text: "Thank you"
    assert_no_link "See our thanks"

    visit thanks_url
    assert_no_text Setting::DEFAULT_THANK_YOU_MESSAGE
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
