require "test_helper"
require "csv"

class ReservationTest < ActiveSupport::TestCase
  def setup
    @reservation = reservations(:reservation_form_minimum)
  end

  test "valid reservation" do
    assert @reservation.valid?
  end

  test "public token is stable and round-trips through find_by_public_token!" do
    token = @reservation.public_token

    assert_equal token, @reservation.reload.public_token
    assert_equal @reservation, Reservation.find_by_public_token!(token)
  end

  test "find_by_public_token! rejects guessable ids and invalid tokens" do
    assert_raises(ActiveRecord::RecordNotFound) { Reservation.find_by_public_token!(@reservation.id.to_s) }
    assert_raises(ActiveRecord::RecordNotFound) { Reservation.find_by_public_token!("not-a-real-token") }
  end

  test "imported status is valid and reports routing status" do
    reservation = Reservation.new(name: "Imported", street: "1 Main", city: "New York", state: "NY", country: "United States", email: "imported.status@example.com", status: "imported")
    assert reservation.valid?
    assert reservation.imported?
    assert_nil reservation.routing_status
  end

  test "migrate_reservations migrates imported reservations" do
    Reservation.create!(name: "Imported", street: "1 Main", city: "New York", state: "NY", country: "United States", email: "imported.migrate@example.com", status: "imported")
    Reservation.migrate_reservations!
    assert Contact.find_by(email: "imported.migrate@example.com")
  end

  test "to_csv exports reservation data" do
    csv = Reservation.to_csv
    assert_includes csv, "email"
    assert_includes csv, reservations(:pending_pickup_1).email
  end

  test "to_csv is an exact copy of the reservations table plus the route" do
    reservation = reservations(:pending_pickup_1)
    csv = Reservation.to_csv

    headers = CSV.parse(csv, headers: true).headers
    assert_equal Reservation::EXPORT_FIELDS, headers
    assert_includes headers, "route"
    assert_includes headers, "stripe_charge_amount"
    assert_includes headers, "heard_about_source"
    assert_includes headers, "is_missing_tree_notifications_enabled"

    rows = CSV.parse(csv, headers: true)
    assert_equal Reservation.count, rows.size

    row = rows.find { |r| r["id"] == reservation.id }
    assert_equal reservation.email, row["email"]
    assert_equal reservation.route_id.to_s, row["route_id"]
    assert_equal reservation.route.name, row["route"]
    assert_equal reservation.status, row["status"]
    assert_equal reservation.confirmed_reservation_email_sent_at.iso8601, row["confirmed_reservation_email_sent_at"]
    assert_equal reservation.created_at.iso8601, row["created_at"]
    assert_equal "true", row["is_missing_tree_notifications_enabled"]
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

  test "changing the street on an incomplete reservation does not promote it to routing" do
    reservation = reservations(:donation_1)
    reservation.update!(street: "500 New Address Ave")

    assert reservation.reload.donation?
    assert_nil reservation.route_id
  end

  test "changing the street resets geocoding and returns a completed reservation to routing" do
    reservation = reservations(:pending_pickup_1)
    reservation.update!(street: "500 New Address Ave")

    assert reservation.reload.routing?
    assert_nil reservation.route_id
    assert_nil reservation.latitude
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

  test "logs a reservation activity when created" do
    assert_difference -> { Log.of_type("reservation").count }, 1 do
      Reservation.create!(name: "Log Test", street: "1 Main St", city: "New York", state: "NY",
                          country: "United States", email: "log.test@example.com")
    end

    log = Log.of_type("reservation").last
    assert_includes log.message, "Reservation created"
    assert_includes log.message, "log.test@example.com"
    assert_equal "Log Test", log.reservation.name
  end

  test "does not log a reservation activity while importing" do
    assert_no_difference -> { Log.of_type("reservation").count } do
      Reservation.create!(name: "Import Log Test", street: "1 Main St", city: "New York", state: "NY",
                          country: "United States", email: "import.log.test@example.com", importing: true)
    end
  end

  test "logs a reservation activity when the status changes" do
    reservation = reservations(:donation_1)

    assert_difference -> { Log.of_type("reservation").count }, 1 do
      reservation.routing!
    end

    log = Log.of_type("reservation").last
    assert_equal reservation, log.reservation
    assert_includes log.message, "donation → routing"
  end

  test "logs a reservation activity when the donation type changes" do
    reservation = reservations(:donation_1)

    assert_difference -> { Log.of_type("reservation").count }, 1 do
      reservation.cash_or_check_donation!
    end

    log = Log.of_type("reservation").last
    assert_equal reservation, log.reservation
    assert_includes log.message, "Cash or check donation"
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

  # remove existing contact (same email) when reservation becomes routing
  test "removing contact on routing" do
    reservation = Reservation.create(name: "Trip Wilson", street: "123 Main St", city: "Anytown", state: "CA", zip: "12345", country: "United States", status: "donation", email: "trip.wilson@example.com")
    assert reservation.donation?
    assert Contact.find_by(email: "trip.wilson@example.com")
    reservation.routing!
    assert reservation.routing?
    assert_not Contact.find_by(email: "trip.wilson@example.com")
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
    # should be 5 contacts based on their status
    assert_not Contact.find_by(email: "form.minimum@example.com") # reservation_form don't get migrated
    assert_not Contact.find_by(email: "john.doe@example.com") # address_verification don't get migrated
    assert_not Contact.find_by(email: "lisa.mills@example.com") # ddonation don't get migrated
    assert Contact.find_by(email: "mary.jones@example.com")
    assert Contact.find_by(email: "bob.jones@example.com")
    assert Contact.find_by(email: "bob.miurtha@example.com")
    assert Contact.find_by(email: "bill.carson@example.com")
  end

  test "migration removes contacts with same email" do
    assert Reservation.find_by(email: "bob.jones@example.com")
    current_reservation = Reservation.find_by(email: "bob.jones@example.com")
    current_reservation.update(name: "Bobby Jones")

    assert Contact.find_by(email: "bob.jones@example.com")
    contact = Contact.find_by(email: "bob.jones@example.com")

    Reservation.migrate_reservations!
    assert_not Reservation.find_by(email: "bob.jones@example.com")
    assert Contact.find_by(email: "bob.jones@example.com")
    assert_equal "Bobby Jones", Contact.find_by(email: "bob.jones@example.com").name
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

  test "search matches name, email, street, and city case-insensitively" do
    assert_includes Reservation.search("mary"), reservations(:pending_pickup_1)
    assert_includes Reservation.search("MARY.JONES@EXAMPLE.COM"), reservations(:pending_pickup_1)
    assert_includes Reservation.search("Broadway"), reservations(:pending_pickup_1)
    assert_includes Reservation.search("new york"), reservations(:pending_pickup_1)
    assert_empty Reservation.search("no-such-reservation")
  end

  test "search with a blank query returns all reservations" do
    assert_equal Reservation.all.count, Reservation.search("").count
    assert_equal Reservation.all.count, Reservation.search("   ").count
    assert_equal Reservation.all.count, Reservation.search(nil).count
  end

  test "search combines with other scopes" do
    assert_includes Reservation.pickup_overview.search("jones"), reservations(:pending_pickup_1)
    assert_includes Reservation.pickup_overview.search("jones"), reservations(:picked_up_1)
    assert_not_includes Reservation.pickup_overview.search("jones"), reservations(:cancelled_1)
    assert_empty Reservation.where(status: "picked_up").search("susan")
  end

  test "pending_pickups_by_route groups pending pickups by route in route-name order" do
    by_route = Reservation.pending_pickups_by_route

    assert_equal [ "Lower Manhattan", "Route 2" ], by_route.map { |route, _reservations| route&.name }

    groups = by_route.to_h { |route, reservations| [ route&.name, reservations ] }
    assert_equal [ "Mack Gilbert", "Mary Jones" ].sort, groups["Lower Manhattan"].map(&:name).sort
    assert_equal [ "Susan Banks" ], groups["Route 2"].map(&:name)
    assert_nil groups["Route 4"] # routes without pending pickups are omitted
    assert_nil groups[nil]
  end

  test "pending_pickups_by_route only includes pending pickups" do
    by_route = Reservation.pending_pickups_by_route
    statuses = by_route.flat_map { |_route, reservations| reservations.map(&:status) }.uniq

    assert_equal [ "pending_pickup" ], statuses
    assert_equal Reservation.pending_pickup.count,
                 by_route.sum { |_route, reservations| reservations.size }
  end

  test "ordered_by_street_address sorts by the street string" do
    route = routes(:one)
    [ "10 Winslow St", "7 Winslow St", "2 Winslow St", "1 Broadway" ].each_with_index do |street, i|
      Reservation.create!(
        name: "Address Order #{i}",
        email: "address.order#{i}@example.com",
        street: street,
        city: "New York", state: "NY", country: "United States",
        status: :pending_pickup,
        route: route
      )
    end

    streets = Reservation.pending_pickup.ordered_by_street_address.where(route: route).pluck(:street)

    assert_equal [ "1 Broadway", "10 Winslow St", "2 Winslow St", "7 Winslow St", "770 Broadway", "770 Broadway" ], streets
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

  test "resend_email! enqueues the requested email" do
    Setting.instance.update(is_emailing_enabled: true)
    reservation = reservations(:pending_pickup_1)

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      reservation.resend_email!("confirmation")
    end
  end

  test "resend_email! raises for an unknown email kind" do
    assert_raises(ArgumentError) do
      reservations(:pending_pickup_1).resend_email!("unknown")
    end
  end
end
