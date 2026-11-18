require "application_system_test_case"

class DonationsTest < ApplicationSystemTestCase
  setup do
    Setting.instance.update(is_donations_enabled: true)
  end

  test "new donation page with donations enabled" do
    make_system_reservation
    assert_selector "h1", text: "Support #{Setting.instance.organization_name}"
    assert_text "Donate Online"
    assert_button "Donate Online"

    assert_text "Donate at Pickup"
    assert_button "Donate at Pickup"

    assert_button "Continue without donation"
  end

  test "new donation page with donations disabled" do
    Setting.instance.update(is_donations_enabled: false)
    make_system_reservation
    assert_selector "h1", text: "Donations"
    assert_text "Support our mission"
    assert_text Setting::DEFAULT_DONATIONS_PAGE_CONTENT
    assert_selector "h2", text: "How to Donate"
    assert_text "leave cash or a check in a ziplock bag with your tree on the day of pickup"
  end

  test "new donation page shows custom donations page content" do
    Setting.instance.update(
      is_donations_enabled: false,
      donations_page_content: "Custom donations intro copy",
      donations_page_how_to_donate: "Custom how to donate copy"
    )
    make_system_reservation
    assert_selector "h2", text: "How to Donate"
    assert_text "Custom donations intro copy"
    assert_text "Custom how to donate copy"
  end

  test "donating at pickup" do
    make_system_reservation
    complete_donation
    assert_selector "h1", text: "Reservation Confirmed"
  end

  test "continue without donation" do
    make_system_reservation
    complete_donation("Continue without donation")
    assert_selector "h1", text: "Reservation Confirmed"
  end

  test "confirming with donations disabled" do
    Setting.instance.update(is_donations_enabled: false)
    make_system_reservation
    click_link "Confirm Your Tree Pickup Reservation"
    assert_selector "h1", text: "Reservation Confirmed"
  end
end
