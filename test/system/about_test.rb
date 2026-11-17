require "application_system_test_case"

class AboutsTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit about_url

    assert_selector "h1", text: "About"
    assert_selector "img[alt='Scouting America']"
  end

  test "should display contact info" do
    setting = Setting.instance
    setting.update(
      contact_name: "John Doe",
      contact_email: "john@example.com",
      contact_phone: "206-555-1212",
      contact_sms: "206-555-3434"
    )

    visit about_url

    assert_text "John Doe"
    assert_text "john@example.com"
    assert_text "206-555-1212"
    assert_text "Contact John Doe at john@example.com or 206-555-1212"
    assert_text "You can also text us at 206-555-3434"
    assert_selector "h4", text: "Questions?"

    setting.update(contact_name: nil, contact_sms: nil)
    visit about_url

    assert_no_text "John Doe"
    assert_text "Contact us at john@example.com or 206-555-1212"
    assert_selector "h4", text: "Questions?"

    setting.update(contact_email: nil)
    visit about_url

    assert_no_text "john@example.com"
    assert_text "Contact us at 206-555-1212"
    assert_selector "h4", text: "Questions?"

    setting.update(contact_phone: nil)
    visit about_url

    assert_no_text "Contact us"
    assert_no_selector "h4", text: "Questions?"

    setting.update(contact_email: "jill@example.com")
    visit about_url

    assert_text "Contact us at jill@example.com"
    assert_selector "h4", text: "Questions?"

    setting.update(contact_email: nil, contact_sms: "206-555-3434")
    visit about_url

    assert_text "Text us at 206-555-3434"
    assert_selector "h4", text: "Questions?"

    setting.update(contact_sms: nil, contact_name: "Jill Doe")
    visit about_url

    assert_text "Contact Jill Doe"
    assert_selector "h4", text: "Questions?"
  end

  test "should display on day of pickup info" do
    setting = Setting.instance
    setting.organization_name = "Troop 222"
    setting.on_day_of_pickup_instructions = "Some instructions"
    setting.save

    visit about_url
    assert_selector "h2", text: "Troop 222"
    assert_text "Some instructions"
    assert_text "Troop 222"
  end

  test "should display about event info" do
    setting = Setting.instance
    setting.about_event_description = "Some description"
    setting.save

    visit about_url
    assert_text "Some description"
  end

  test "should display day of pickup info" do
    setting = Setting.instance
    setting.event_pickup_start = "2025-01-01 10:00:00"
    setting.save

    visit about_url
    assert_text "January 1, 2025"
  end

  test "should display pickup time" do
    setting = Setting.instance
    setting.event_pickup_start = "2025-01-01 10:00:00"
    setting.event_pickup_end = "2025-01-01 15:00:00"
    setting.save

    visit about_url
    assert_text "10:00am - 3:00pm"
  end

  test "should display organization url" do
    setting = Setting.instance
    setting.organization_url = nil
    setting.save

    visit about_url
    assert_no_link "Learn more"

    setting.organization_url = "https://example.com"
    setting.save

    visit about_url
    assert_link "Learn more", href: "https://example.com"
  end

  test "should display the configured thank you message" do
    Setting.instance.update!(thank_you_message: "Custom thanks to our community.")

    visit about_url

    assert_text "Custom thanks to our community."
  end

  test "should hide the thank you section when the message is cleared" do
    Setting.instance.update!(thank_you_message: "")

    visit about_url

    assert_no_selector "h3", text: "Thank you"
    assert_no_link "See our thanks"
  end

  test "should link to thanks only when thanks exist" do
    visit about_url

    assert_link "See our thanks", href: thanks_path

    Thank.delete_all
    visit about_url

    assert_no_link "See our thanks"
  end
end
