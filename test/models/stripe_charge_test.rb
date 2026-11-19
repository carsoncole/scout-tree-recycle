require "test_helper"
require "ostruct"

class StripeChargeTest < ActiveSupport::TestCase
  test "paid checkout session confirms the reservation in the donation step" do
    reservation = reservations(:donation_1)

    StripeCharge.new(checkout_event(reservation, payment_status: "paid")).process

    assert_equal "routing", reservation.reload.status
    donation = Donation.find_by(stripe_payment_intent_id: "pi_paid")
    assert_not_nil donation
    assert_equal reservation.id, donation.reservation_id
    assert_equal 25.0, donation.amount
  end

  test "unpaid checkout session leaves the reservation untouched" do
    reservation = reservations(:donation_with_mobile)

    StripeCharge.new(checkout_event(reservation, payment_status: "unpaid")).process

    assert_equal "donation", reservation.reload.status
  end

  test "paid checkout session does not resurrect a cancelled reservation" do
    reservation = reservations(:cancelled_1)

    StripeCharge.new(checkout_event(reservation, payment_status: "paid")).process

    assert_equal "cancelled", reservation.reload.status
  end

  test "paid checkout session without a reservation only records the donation" do
    event = OpenStruct.new(
      data: OpenStruct.new(
        object: OpenStruct.new(
          object: "checkout.session",
          id: "cs_orphan",
          client_reference_id: nil,
          amount_total: 2500,
          status: "complete",
          customer_email: "friend@example.com",
          payment_intent: "pi_orphan",
          payment_status: "paid",
          customer_details: OpenStruct.new(email: "friend@example.com", name: "A Friend")
        )
      )
    )

    StripeCharge.new(event).process

    assert_not_nil Donation.find_by(stripe_payment_intent_id: "pi_orphan")
  end

  private

  def checkout_event(reservation, payment_status:)
    OpenStruct.new(
      data: OpenStruct.new(
        object: OpenStruct.new(
          object: "checkout.session",
          id: "cs_#{payment_status}",
          client_reference_id: reservation.id,
          amount_total: 2500,
          status: "complete",
          customer_email: reservation.email,
          payment_intent: "pi_#{payment_status}",
          payment_status: payment_status,
          customer_details: OpenStruct.new(email: reservation.email, name: reservation.name)
        )
      )
    )
  end
end
