require "application_system_test_case"

class PriorReservationsTest < ApplicationSystemTestCase
  test "unsubscribe from prior reservations" do
    visit unsubscribe_prior_reservation_url(prior_reservations(:full).id)
    click_on "Yes, Unsubscribe Me"
    assert_text "You have been successfully unsubscribed from our mailing list."
    assert_not PriorReservation.exists?(prior_reservations(:full).id)
  end

  test "unsubscribe from prior reservations with wrong id" do
    visit unsubscribe_prior_reservation_url(1234567890)
    assert_text "Your email has already been unsubscribed."
    assert_text "Make a Reservation"
  end
end
