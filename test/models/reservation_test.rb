require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  def setup
    @reservation = create(:reservation)
  end

  test "valid reservation" do
    assert @reservation.valid?
  end

  test "requires name" do
    @reservation.name = nil
    assert_not @reservation.valid?
    assert_includes @reservation.errors[:name], "can't be blank"
  end

  test "requires street" do
    @reservation.street = nil
    assert_not @reservation.valid?
    assert_includes @reservation.errors[:street], "can't be blank"
  end

  test "requires email" do
    @reservation.email = nil
    assert_not @reservation.valid?
    assert_includes @reservation.errors[:email], "can't be blank"
  end

  test "phone is optional" do
    @reservation.phone = nil
    assert @reservation.valid?
  end

  test "notes are optional" do
    @reservation.notes = nil
    assert @reservation.valid?
  end

  test "city is set from settings" do
    assert_equal Setting.instance.default_city, @reservation.city
  end

  test "short_address returns street and city" do
    assert_equal @reservation.street + ", " + @reservation.city + ", " + @reservation.state, @reservation.short_address
  end

  test "can be cancelled" do
    @reservation.save
    @reservation.cancelled!
    assert @reservation.cancelled?
  end

  test "can be marked as picked up" do
    @reservation.picked_up!
    assert @reservation.picked_up?
  end

  test "scopes work correctly" do
    # Create some test reservations
    @reservation_2 = create(:reservation)
    @reservation_2.cancelled!

    @reservation_3 = create(:reservation)
    @reservation_3.picked_up!

    @reservation_4 = create(:pending_pickup_reservation)

    assert_equal 1, Reservation.reservation_form.count
    assert_equal 1, Reservation.cancelled.count
    assert_equal 1, Reservation.picked_up.count
    assert_equal 1, Reservation.pending_pickup.count
  end

  test "invalid without email" do
    reservation = build(:reservation, email: nil)
    assert_not reservation.valid?
    assert_includes reservation.errors[:email], "can't be blank"
  end

  test "invalid without street" do
    reservation = build(:reservation, street: nil)
    assert_not reservation.valid?
    assert_includes reservation.errors[:street], "can't be blank"
  end

  test "invalid without city" do
    reservation = build(:reservation, city: nil)
    assert_not reservation.valid?
    assert_includes reservation.errors[:city], "can't be blank"
  end

  test "invalid without state" do
    reservation = build(:reservation, state: nil)
    assert_not reservation.valid?
    assert_includes reservation.errors[:state], "can't be blank"
  end

  test "invalid with duplicate email" do
    # Create first reservation
    create(:reservation, email: "duplicate@example.com", status: :pending_pickup)

    # Try to create second reservation with same email
    reservation = build(:reservation, email: "duplicate@example.com")
    assert_not reservation.valid?
    assert_includes reservation.errors[:email], "has already been taken"
  end

  # remove existing prior_reservation (same email) when reservation becomes pending pickup
  test "removing prior reservation on pending pickup" do
    prior = create(:prior_reservation, email: "test@example.com")
    reservation = create(:reservation, email: "test@example.com")
    assert PriorReservation.find_by(email: "test@example.com")
    reservation.update(status: :pending_pickup)
    assert_not PriorReservation.find_by(email: "test@example.com")
    assert Reservation.find_by(email: "test@example.com")
    assert_equal "pending_pickup", reservation.status
  end

  test "normalizing of phone number" do
    reservation = create(:reservation, phone: "1234567890")
    assert_equal "+11234567890", reservation.phone

    reservation = create(:reservation, phone: "123-456-7890")
    assert_equal "+11234567890", reservation.phone

    reservation = create(:reservation, phone: "(123) 456-7890")
    assert_equal "+11234567890", reservation.phone

    reservation = create(:reservation, phone: "(123)456-7890")
    assert_equal "+11234567890", reservation.phone

    reservation = create(:reservation, phone: "123.456.7890")
    assert_equal "+11234567890", reservation.phone
  end

  test "downcasing of email" do
    reservation = create(:reservation, email: "TEST@EXAMPLE.COM")
    assert_equal "test@example.com", reservation.email
  end

end
