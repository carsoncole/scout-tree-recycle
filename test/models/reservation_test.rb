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

  test "validates email format" do
    @reservation.email = "invalid-email"
    assert_not @reservation.valid?
    assert_includes @reservation.errors[:email], "is invalid"
  end

  test "phone is optional" do
    @reservation.phone = nil
    assert @reservation.valid?
  end

  test "validates phone format if present" do
    @reservation.phone = "invalid-phone"
    assert_not @reservation.valid?
    assert_includes @reservation.errors[:phone], "is invalid"
  end

  test "notes are optional" do
    @reservation.notes = nil
    assert @reservation.valid?
  end

  test "city is set from settings" do
    assert_equal Setting.instance.default_city, @reservation.city
  end

  test "short_address returns street and city" do
    assert_equal "215 Ericksen Ave NE, Bainbridge Island, Washington", @reservation.short_address
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

    assert_equal 1, Reservation.in_process.count
    assert_equal 1, Reservation.cancelled.count
    assert_equal 1, Reservation.picked_up.count
  end
end 
