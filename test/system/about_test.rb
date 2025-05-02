require "application_system_test_case"

class AboutsTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit about_url

    assert_selector "h1", text: "About"
  end

  test "should display contact info" do
    setting = Setting.instance
    setting.contact_name = "John Doe"
    setting.contact_email = "john@example.com"
    setting.contact_phone = "206-555-1212"
    setting.save

    visit about_url

    assert_text "John Doe"
    assert_text "john@example.com"
    assert_text "206-555-1212"
    assert_text "Questions?"

    setting.update(contact_name: nil)
    visit about_url

    assert_no_text "John Doe"
    assert_text "john@example.com"
    assert_text "206-555-1212"
    assert_text "Questions?"

    setting.update(contact_email: nil)
    visit about_url

    assert_no_text "John Doe"
    assert_no_text "john@example.com"
    assert_text "206-555-1212"
    assert_text "Questions?"

    setting.update(contact_phone: nil)
    visit about_url

    assert_no_text "John Doe"
    assert_no_text "john@example.com"
    assert_no_text "206-555-1212"
    assert_no_text "Questions?"
  end

  test "should diplay on day of pickup info" do
    setting = Setting.instance
    setting.on_day_of_pickup_instructions = "Some instructions"
    setting.save

    visit about_url

    assert_text "Some instructions"
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
    setting.event_pickup = "2025-01-01 10:00:00 -0800"
    setting.save

    visit about_url
    assert_text "January 1, 2025"
  end

  test "should display pickup time" do
    setting = Setting.instance
    setting.event_pickup = "2025-01-01 10:00:00 -0800"
    setting.event_pickup_end = "2025-01-01 15:00:00 -0800"
    setting.save

    visit about_url
    assert_text "6:00pm"
    assert_text "11:00pm"
  end

  test "should display organization url" do
    setting = Setting.instance
    setting.save

    visit about_url
    assert_no_link "Learn more"

    setting.organization_url = "https://example.com"
    setting.save

    visit about_url
    assert_link "Learn more", href: "https://example.com"
  end
end
