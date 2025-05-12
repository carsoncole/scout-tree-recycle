require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  def setup
    @reservation = reservations(:pending_pickup_1)
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
    @reservation.pickup_notes = nil
    assert @reservation.valid?
  end

  test "city is set from settings" do
    assert_equal "Bainbridge Island", @reservation.city
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

  test "invalid without email" do
    reservation = reservations(:pending_pickup_1)
    reservation.email = nil
    assert_not reservation.valid?
    assert_includes reservation.errors[:email], "can't be blank"
  end

  test "invalid without street" do
    reservation = reservations(:pending_pickup_1)
    reservation.street = nil
    assert_not reservation.valid?
    assert_includes reservation.errors[:street], "can't be blank"
  end

  test "invalid without city" do
    reservation = reservations(:pending_pickup_1)
    reservation.city = nil
    assert_not reservation.valid?
    assert_includes reservation.errors[:city], "can't be blank"
  end

  test "invalid without state" do
    reservation = reservations(:pending_pickup_1)
    reservation.state = nil
    assert_not reservation.valid?
    assert_includes reservation.errors[:state], "can't be blank"
  end

  test "invalid with duplicate email" do
    # Try to create second reservation with same email (routing_1 is existing)
    reservation = Reservation.new(email: "icky.jones@example.com")
    assert_not reservation.valid?
    assert_includes reservation.errors[:email], "has already been taken"
  end

  test "before_validation :destroy_not_pending_reservations! removes not pending reservations" do
    assert_equal reservations(:donation_1).id, Reservation.find_by(email: "lisa.mills@example.com").id
    assert_equal "donation", Reservation.find_by(email: "lisa.mills@example.com").status
    new_reservation = Reservation.create(email: "lisa.mills@example.com", name: "aa", street: "123 Main St", city: "Anytown", state: "CA", zip: "12345", country: "United States")

    assert_not Reservation.find_by(id: reservations(:donation_1).id)
    assert Reservation.find_by(id: new_reservation.id)
  end

  # remove existing prior_reservation (same email) when reservation becomes pending pickup
  test "removing prior reservation on routing" do
    reservation = Reservation.create(name: "Trip Wilson", street: "123 Main St", city: "Anytown", state: "CA", zip: "12345", country: "United States", status: "donation", email: "trip.wilson@example.com")
    assert PriorReservation.find_by(email: "trip.wilson@example.com")
    reservation.routing!
    assert_not PriorReservation.find_by(email: "trip.wilson@example.com")
    assert Reservation.find_by(email: "susan.banks@example.com")
    assert reservation.routing?
  end

  test "normalizing of mobile number" do
    reservation = reservations(:routing_1)
    reservation.update(mobile: "1234567890")
    assert_equal "+11234567890", reservation.mobile

    reservation = reservations(:routing_1)
    reservation.update(mobile: "123-456-7890")
    assert_equal "+11234567890", reservation.mobile

    reservation = reservations(:routing_1)
    reservation.update(mobile: "(123) 456-7890")
    assert_equal "+11234567890", reservation.mobile

    reservation = reservations(:routing_1)
    reservation.update(mobile: "(123)456-7890")
    assert_equal "+11234567890", reservation.mobile

    reservation = reservations(:routing_1)
    reservation.update(mobile: "123.456.7890")
    assert_equal "+11234567890", reservation.mobile
  end

  test "downcasing of email" do
    reservation = reservations(:routing_1)
    reservation.update(email: "TEST@EXAMPLE.COM")
    assert_equal "test@example.com", reservation.email
  end

  test "migrating reservations" do
    assert_equal 13, Reservation.count
    assert_equal 3, PriorReservation.count

    Reservation.migrate_reservations!

    # should not be any reservations
    assert_not Reservation.find_by(email: "steve.jobs@example.com")
    assert_not Reservation.find_by(email: "john.doe@example.com")
    assert_not Reservation.find_by(email: "lisa.mills@example.com")
    assert_not Reservation.find_by(email: "mary.jones@example.com")
    assert_not Reservation.find_by(email: "bob.jones@example.com")
    assert_not Reservation.find_by(email: "bob.miurtha@example.com")
    assert_not Reservation.find_by(email: "bill.carson@example.com")
    # should be 5 prior reservations based on their status
    assert_not PriorReservation.find_by(email: "steve.jobs@example.com") # reservation_form don't get migrated
    assert_not PriorReservation.find_by(email: "john.doe@example.com") # address_verification don't get migrated
    assert_not PriorReservation.find_by(email: "lisa.mills@example.com") # ddonation don't get migrated
    assert PriorReservation.find_by(email: "mary.jones@example.com")
    assert PriorReservation.find_by(email: "bob.jones@example.com")
    assert PriorReservation.find_by(email: "bob.miurtha@example.com")
    assert PriorReservation.find_by(email: "bill.carson@example.com")
  end

  test "migration removes prior reservations with same email" do
    assert Reservation.find_by(email: "bob.jones@example.com")
    current_reservation = Reservation.find_by(email: "bob.jones@example.com")
    current_reservation.update(name: "Bobby Jones")

    assert PriorReservation.find_by(email: "bob.jones@example.com")
    prior_reservation = PriorReservation.find_by(email: "bob.jones@example.com")

    Reservation.migrate_reservations!
    assert_not Reservation.find_by(email: "bob.jones@example.com")
    assert PriorReservation.find_by(email: "bob.jones@example.com")
    assert_equal "Bobby Jones", PriorReservation.find_by(email: "bob.jones@example.com").name
  end

  test "reset_geocoding! resets geocoding data" do
    reservation = reservations(:pending_pickup_1)
    reservation.reset_geocoding!
    assert_nil reservation.latitude
    assert_nil reservation.longitude
    assert_nil reservation.route_id
    assert_nil reservation.distance_to_route
    assert_not reservation.was_automatically_geocoded
  end

  test "reset_geocoding! does not reset geocoding data if it's manually geocoded" do
    reservation = reservations(:pending_pickup_not_routed)
    reservation.reset_geocoding!
    assert_not_nil reservation.latitude
    assert_not_nil reservation.longitude
  end

  test "routing reset when latitude is changed to nil" do
    reservation = reservations(:pending_pickup_1)
    reservation.update(latitude: "")
    assert reservation.routing?
    assert_nil reservation.latitude
    assert_nil reservation.longitude
    assert_nil reservation.route_id
    assert_nil reservation.distance_to_route
    assert_not reservation.was_automatically_geocoded
  end

  test "routing reset when longitude is changed to nil" do
    reservation = reservations(:pending_pickup_1)
    reservation.update(longitude: "")
    assert reservation.routing?
    assert_nil reservation.latitude
    assert_nil reservation.longitude
    assert_nil reservation.route_id
    assert_nil reservation.distance_to_route
    assert_not reservation.was_automatically_geocoded
  end

  test "manual routing set when when manually setting route and not affecting coordinates" do
    reservation = reservations(:pending_pickup_1)
    reservation.update(route_id: routes(:three).id)
    assert reservation.is_manually_routed
    assert_not reservation.was_automatically_routed
    assert reservation.latitude
    assert reservation.longitude
  end

  test "removing route removes is_manually_routed" do
    reservation = reservations(:pending_pickup_1)
    reservation.update(route_id: nil)
    assert_not reservation.is_manually_routed
  end

  # test "reset_geocoding and status to routing when address is changed" do
  #   reservation = reservations(:pending_pickup_1)
  #   assert_equal "176 Harlan St", reservation.street
  #   reservation.update(street: "123 Main St", city: "Anytown", state: "CA", zip: "12345")
  #   reservation.reload
  #   assert_equal "routing", reservation.status
  #   assert_nil reservation.latitude
  #   assert_nil reservation.longitude
  # end

  # test "routing has no route" do
  #   assert_not reservations(:routing_1).route
  # end

  # test "pending pickup has a route" do
  #   assert reservations(:pending_pickup_1).route
  # end

  # test "status changes to routing when route is removed" do
  #   reservation = reservations(:pending_pickup_1)
  #   reservation.route = nil
  #   reservation.save
  #   assert reservation.routing?
  # end

  # test "status changes to pending pickup when route is added" do
  #   reservation = reservations(:routing_1)
  #   reservation.route = routes(:one)
  #   reservation.save
  #   assert reservation.pending_pickup?
  # end

  # test "is_manually_geocoded when changing coordinates on pending pickup reservation" do
  #   reservation = reservations(:pending_pickup_1)
  #   reservation.update(latitude: 47.64011, longitude: -122.527945)
  #   assert reservation.is_manually_geocoded
  #   assert reservation.routing?
  # end

  # test  "resetting to automatic geocoding when coordinates removed" do
  #   reservation = reservations(:pending_pickup_not_routed)
  #   assert reservation.is_manually_geocoded
  #   reservation.update(latitude: nil, longitude: nil)
  #   assert_not reservation.is_manually_geocoded
  # end

end  
