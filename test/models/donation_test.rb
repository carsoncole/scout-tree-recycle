require "test_helper"

class DonationTest < ActiveSupport::TestCase
  test "logs a donation activity when the donation is paid" do
    reservation = reservations(:donation_1)
    donation = Donation.create!(reservation: reservation, stripe_payment_intent_id: "pi_donation_log")

    assert_no_difference -> { Log.of_type("donation").count } do
      donation.update!(amount: 25.0, status: "complete", payment_status: "unpaid")
    end

    assert_difference -> { Log.of_type("donation").count }, 1 do
      donation.update!(amount: 25.0, status: "complete", payment_status: "paid")
    end

    log = Log.of_type("donation").last
    assert_equal reservation, log.reservation
    assert_includes log.message, "Online donation received $25.00"
  end

  test "does not log a reservation activity for donations without a reservation" do
    donation = Donation.create!(stripe_payment_intent_id: "pi_donation_orphan")

    assert_no_difference -> { Log.count } do
      donation.update!(amount: 10.0, status: "complete", payment_status: "paid")
    end
  end
end
