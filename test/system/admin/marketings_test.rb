require "application_system_test_case"

class Admin::MarketingsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the index" do
    visit admin_marketing_index_url

    assert_selector "h1", text: "Marketing"
  end

  test "index explains that marketing emails are only sent once per contact" do
    visit admin_marketing_index_url

    assert_text "Sent only once per contact. Contacts who already received Marketing email 1 are skipped"
    assert_text "Sent only once per contact. Contacts who already received Marketing email 2 are skipped"
  end

  test "index notes that prior reservations are removed for confirmed reservations" do
    visit admin_marketing_index_url

    assert_text "Any prior reservations with the same email as a newly confirmed reservation are removed automatically"
  end

  test "adding a prior reservation" do
    visit admin_marketing_index_url
    click_on "New Contact"

    fill_in "Name", with: "Jordan Fields"
    fill_in "Email", with: "Jordan.Fields@example.com"
    fill_in "Mobile", with: "555-555-5555"
    fill_in "Street", with: "7 Pine Rd"
    click_on "Create Prior Reservation"

    assert_text "Prior reservation was successfully created."
    assert_text "jordan.fields@example.com"
    assert_equal "Jordan Fields", PriorReservation.find_by(email: "jordan.fields@example.com").name
  end

  test "editing a prior reservation" do
    visit admin_marketing_index_url

    within "tr", text: prior_reservations(:full).email do
      click_on "Edit"
    end

    fill_in "Name", with: "Susan B. Banks"
    click_on "Update Prior Reservation"

    assert_text "Prior reservation was successfully updated."
    assert_text "Susan B. Banks"
  end

  test "shows the local date and time each marketing email was sent" do
    sent_at = Time.zone.parse("2026-01-15 09:30")
    prior_reservations(:full).update!(marketing_1_email_sent_at: sent_at, marketing_2_email_sent_at: sent_at)

    visit admin_marketing_index_url

    within "tr", text: prior_reservations(:full).email do
      assert_text "Jan 15, 2026 9:30 AM", count: 2
    end
  end

  test "delete all prior reservations with confirmation" do
    visit admin_marketing_index_url
    assert_text "3 prior reservations"
    find("summary", text: "Delete All Prior Reservations").click
    fill_in "Type DELETE to confirm", with: "DELETE"
    click_on "Confirm Delete All Prior Reservations"

    assert_text "3 prior reservations have been deleted."
    assert_text "No prior reservations are available for marketing."
    assert_equal 0, PriorReservation.count
  end
end
