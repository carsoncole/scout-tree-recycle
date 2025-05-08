require "test_helper"

class PriorReservationTest < ActiveSupport::TestCase
  test "is valid" do
    assert prior_reservations(:one).valid?
  end

  test "is invalid without email" do
    prior_reservation = prior_reservations(:one)
    prior_reservation.email = nil 
    assert_not prior_reservation.valid?
  end

  test "is invalid without name" do
    prior_reservation = prior_reservations(:one)
    prior_reservation.name = nil
    assert_not prior_reservation.valid?
  end
end
