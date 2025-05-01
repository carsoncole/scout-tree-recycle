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

  test "mobile is optional" do
    @reservation.mobile = nil
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

  test "before_validation :destroy_not_pending_reservations! removes not pending reservations" do
    reservation = create(:reservation, email: "test@example.com", status: :reservation_form)
    assert_equal reservation.id, Reservation.find_by(email: "test@example.com").id
    new_reservation = create(:reservation, email: "test@example.com", status: :donation_type_selection)

    assert_not Reservation.find_by(id: reservation.id)
    assert Reservation.find_by(id: new_reservation.id)
  end

  # remove existing prior_reservation (same email) when reservation becomes pending pickup
  test "removing prior reservation on pending pickup" do
    prior = create(:prior_reservation, email: "test@example.com")
    reservation = create(:reservation, status: :donation_type_selection, email: "test@example.com")
    assert PriorReservation.find_by(email: "test@example.com")
    reservation.pending_pickup!
    assert_not PriorReservation.find_by(email: "test@example.com")
    assert Reservation.find_by(email: "test@example.com")
    assert reservation.pending_pickup?
  end

  test "normalizing of mobile number" do
    reservation = create(:reservation, mobile: "1234567890")
    assert_equal "+11234567890", reservation.mobile

    reservation = create(:reservation, mobile: "123-456-7890")
    assert_equal "+11234567890", reservation.mobile

    reservation = create(:reservation, mobile: "(123) 456-7890")
    assert_equal "+11234567890", reservation.mobile

    reservation = create(:reservation, mobile: "(123)456-7890")
    assert_equal "+11234567890", reservation.mobile

    reservation = create(:reservation, mobile: "123.456.7890")
    assert_equal "+11234567890", reservation.mobile
  end

  test "downcasing of email" do
    reservation = create(:reservation, email: "TEST@EXAMPLE.COM")
    assert_equal "test@example.com", reservation.email
  end

  test "migrating reservations" do
    reservation_form_reservation = create(:reservation, email: "reservation_form@example.com", status: :reservation_form)
    address_verification_reservation = create(:reservation, email: "address_verification@example.com", status: :address_verification)
    donation_selection_reservation = create(:reservation, email: "donation@example.com", status: :donation_type_selection)
    pending_reservation = create(:pending_pickup_reservation, email: "pending_pickup@example.com")
    picked_up_reservation = create(:reservation, email: "picked_up@example.com", status: :picked_up)    
    cancelled_reservation = create(:reservation, email: "cancelled@example.com", status: :cancelled)
    missing_reservation = create(:reservation, email: "missing@example.com", status: :missing)

    assert_equal 8, Reservation.count
    assert_equal 0, PriorReservation.count

    Reservation.migrate_reservations!

    # should not be any reservations
    assert_not Reservation.find_by(email: "reservation_form@example.com")
    assert_not Reservation.find_by(email: "pending_pickup@example.com")
    assert_not Reservation.find_by(email: "donation@example.com")
    assert_not Reservation.find_by(email: "cancelled@example.com")
    assert_not Reservation.find_by(email: "address_verification@example.com")
    assert_not Reservation.find_by(email: "picked_up@example.com")
    assert_not Reservation.find_by(email: "missing@example.com")
    # should be 5 prior reservations based on their status
    assert_not PriorReservation.find_by(email: "reservation_form@example.com") # reservation_form don't get migrated
    assert_not PriorReservation.find_by(email: "address_verification@example.com") # address_verification don't get migrated
    assert_not PriorReservation.find_by(email: "donation@example.com") # donation_type_selection don't get migrated
    assert PriorReservation.find_by(email: "pending_pickup@example.com")
    assert PriorReservation.find_by(email: "picked_up@example.com")
    assert PriorReservation.find_by(email: "cancelled@example.com")
    assert PriorReservation.find_by(email: "missing@example.com")
  end
end