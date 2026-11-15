require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  def setup
    @reservation = reservations(:reservation_form_minimum)
  end

  test "valid reservation" do
    assert @reservation.valid?
  end

  test "imported status is valid and reports routing status" do
    reservation = Reservation.new(name: "Imported", street: "1 Main", city: "New York", state: "NY", country: "United States", email: "imported.status@example.com", status: "imported")
    assert reservation.valid?
    assert reservation.imported?
    assert_equal "Imported", reservation.routing_status
  end

  test "migrate_reservations migrates imported reservations" do
    Reservation.create!(name: "Imported", street: "1 Main", city: "New York", state: "NY", country: "United States", email: "imported.migrate@example.com", status: "imported")
    Reservation.migrate_reservations!
    assert PriorReservation.find_by(email: "imported.migrate@example.com")
  end

  test "to_csv exports reservation data" do
    csv = Reservation.to_csv
    assert_includes csv, "email"
    assert_includes csv, reservations(:pending_pickup_1).email
  end

  test "validates name" do
    @reservation.name = nil
    assert_not @reservation.valid?
    assert_includes @reservation.errors[:name], "can't be blank"
  end

  test "validates street" do
    @reservation.street = nil
    assert_not @reservation.valid?
    assert_includes @reservation.errors[:street], "can't be blank"
  end

  test "validates email" do
    @reservation.email = nil
    assert_not @reservation.valid?
    assert_includes @reservation.errors[:email], "can't be blank"
  end

  test "city, state, and country are set from settings" do
    reservation = Reservation.new

    assert_equal "New York", reservation.city
    assert_equal "New York", reservation.state
    assert_equal "United States", reservation.country

    Setting.instance.update(default_country: "Canada")
    assert_equal "Canada", Reservation.new.country
  end

  test "short_address returns street and city" do
    assert_equal @reservation.street + ", " + @reservation.city + ", " + @reservation.state, @reservation.short_address
  end

  test "can be cancelled" do
    @reservation.cancelled!
    assert @reservation.cancelled?
  end

  test "can be picked up" do
    @reservation.picked_up!
    assert @reservation.picked_up?
  end

  test "invalid with duplicate email" do
    # Try to create second reservation with same email (routing_1 is existing)
    reservation = Reservation.new(email: "icky.jones@example.com")
    assert_not reservation.valid?
    assert_includes reservation.errors[:email], "has already been taken"
  end

  test "detroying reservation_form with same email " do
    reservation = reservations(:reservation_form_minimum)
    email = reservation.email
    assert reservation.reservation_form?

    new_reservation_with_same_email = Reservation.create(email: email, status: "reservation_form", name: "J Smith", street: "123 Main")

    assert_not Reservation.find_by(id: reservation.id)
  end

  test "detroying donation reservation with same email" do
    reservation = reservations(:donation_1)
    email = reservation.email
    assert reservation.donation?

    new_reservation_with_same_email = Reservation.create(email: email, status: "donation", name: "J Smith", street: "123 Main")

    assert_not Reservation.find_by(id: new_reservation_with_same_email.id)
  end

  test "detroying cancelled reservation with same email" do
    reservation = reservations(:cancelled_1)
    email = reservation.email
    assert reservation.cancelled?

    new_reservation_with_same_email = Reservation.create(email: email, status: "cancelled", name: "J Smith", street: "123 Main")

    assert_not Reservation.find_by(id: new_reservation_with_same_email.id)
  end

  test "destroying address verification reservation with same email" do
    reservation = reservations(:address_verification_1)
    email = reservation.email
    assert reservation.address_verification?

    new_reservation_with_same_email = Reservation.create(email: email, status: "address_verification", name: "J Smith", street: "123 Main")

    assert_not Reservation.find_by(id: new_reservation_with_same_email.id)
  end

  # remove existing prior_reservation (same email) when reservation becomes routing
  test "removing prior reservation on routing" do
    reservation = Reservation.create(name: "Trip Wilson", street: "123 Main St", city: "Anytown", state: "CA", zip: "12345", country: "United States", status: "donation", email: "trip.wilson@example.com")
    assert reservation.donation?
    assert PriorReservation.find_by(email: "trip.wilson@example.com")
    reservation.routing!
    assert reservation.routing?
    assert_not PriorReservation.find_by(email: "trip.wilson@example.com")
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
    # existing reservations
    assert Reservation.find_by(email: "form.minimum@example.com")
    assert Reservation.find_by(email: "john.doe@example.com")
    assert Reservation.find_by(email: "lisa.mills@example.com")
    assert Reservation.find_by(email: "mary.jones@example.com")
    assert Reservation.find_by(email: "bob.jones@example.com")
    assert Reservation.find_by(email: "bob.miurtha@example.com")
    assert Reservation.find_by(email: "bill.carson@example.com")

    Reservation.migrate_reservations!

    # should not be any reservations
    assert_not Reservation.find_by(email: "form.minimum@example.com")
    assert_not Reservation.find_by(email: "john.doe@example.com")
    assert_not Reservation.find_by(email: "lisa.mills@example.com")
    assert_not Reservation.find_by(email: "mary.jones@example.com")
    assert_not Reservation.find_by(email: "bob.jones@example.com")
    assert_not Reservation.find_by(email: "bob.miurtha@example.com")
    assert_not Reservation.find_by(email: "bill.carson@example.com")
    # should be 5 prior reservations based on their status
    assert_not PriorReservation.find_by(email: "form.minimum@example.com") # reservation_form don't get migrated
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

  test "reset_geocoding! resets geocoding data AND routing data" do
    reservation = reservations(:pending_pickup_1)
    reservation.reset_geocoding!
    assert_nil reservation.latitude
    assert_nil reservation.longitude
    assert_nil reservation.route_id
    assert_not reservation.was_automatically_geocoded
    assert_not reservation.was_automatically_routed
    assert_nil reservation.distance_to_route
    assert_not reservation.is_manually_routed
    assert_not reservation.is_manually_geocoded
  end

  test "reset_routing! resets routing data AND NOT geocoding data" do
    reservation = reservations(:pending_pickup_not_routed)
    reservation.latitude = 123
    reservation.longitude = 456
    reservation.was_automatically_geocoded = true
    reservation.reset_routing!
    assert_nil reservation.route_id
    assert_not reservation.was_automatically_routed
    assert_nil reservation.distance_to_route
    assert_not reservation.is_manually_routed
    assert reservation.was_automatically_geocoded
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

  test "status_higher_than? returns true if status is higher than the other status" do
    assert reservations(:pending_pickup_1).status_higher_than?("routing")
    assert_not reservations(:pending_pickup_1).status_higher_than?("picked_up")
  end

  test "status_lower_than? returns true if status is lower than the other status" do
    assert reservations(:pending_pickup_1).status_lower_than?("picked_up")
    assert_not reservations(:pending_pickup_1).status_lower_than?("routing")
  end

  test "scope routing_ready returns reservations that are ready for routing" do
    assert_equal 4, Reservation.routing_ready.count
  end

  test "reset_geocoding and status to routing when address is changed" do
    reservation = reservations(:pending_pickup_1)
    reservation.update(street: "1 East 161st St")
    reservation.reload
    assert_equal "routing", reservation.status
    assert_nil reservation.latitude
    assert_nil reservation.longitude
  end

  test "status changes to routing when route is removed" do
    reservation = reservations(:pending_pickup_1)
    reservation.route_id = nil
    reservation.save
    assert reservation.routing?
  end

  test "status changes to pending pickup when route is added" do
    reservation = reservations(:routing_1)
    reservation.route = routes(:one)
    reservation.save
    assert reservation.pending_pickup?
  end

  test "is_manually_geocoded when changing coordinates on pending pickup reservation" do
    reservation = reservations(:pending_pickup_1)
    reservation.update(latitude: 47.64011, longitude: -122.527945)
    assert reservation.is_manually_geocoded
    assert reservation.routing?
  end

  test "resetting to automatic geocoding when coordinates removed" do
    reservation = reservations(:pending_pickup_not_routed)
    assert reservation.is_manually_geocoded
    reservation.update(latitude: nil, longitude: nil)
    assert_not reservation.is_manually_geocoded
  end
end
