require "test_helper"

class Admin::ReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_reservations_url
    assert_response :success
  end

  test "index shows pickup reminder batch details" do
    Setting.instance.update!(email_batch_quantity: 2)
    sign_in

    get admin_reservations_url

    assert_response :success
    assert_select "section[aria-labelledby=pickup-reminder-email-title]" do
      assert_select "h2", text: "Pickup reminder email"
      assert_select "form[action=?]", send_pickup_reminder_emails_admin_reservations_path
      assert_match "#{Reservation.pickup_reminder_pending.count} emails remaining", response.body
      assert_match "Batch size:", response.body
    end
  end

  test "queues a batch of pickup reminder emails" do
    configure_email!
    sign_in
    count = Reservation.pickup_reminder_pending.count

    assert_enqueued_with(job: SendPickupReminderEmailsJob) do
      post send_pickup_reminder_emails_admin_reservations_url
    end

    assert_redirected_to admin_reservations_url
    assert_equal "#{Setting.instance.email_batch_size(count)} of #{count} pickup reminder emails queued to be sent.", flash[:notice]
  end

  test "does not queue pickup reminders when emailing is disabled" do
    Setting.instance.update!(is_emailing_enabled: false)
    sign_in

    assert_no_enqueued_jobs do
      post send_pickup_reminder_emails_admin_reservations_url
    end

    assert_redirected_to admin_reservations_url
    assert_equal "Emailing is disabled. Enable it in Settings before sending pickup reminder emails.", flash[:alert]
  end

  test "does not queue pickup reminders without eligible reservations" do
    configure_email!
    Reservation.pickup_reminder_pending.update_all(pickup_reminder_email_sent_at: Time.current)
    sign_in

    assert_no_enqueued_jobs do
      post send_pickup_reminder_emails_admin_reservations_url
    end

    assert_redirected_to admin_reservations_url
    assert_equal "No reservations are eligible for a pickup reminder email.", flash[:alert]
  end

  test "does not queue pickup reminders when the template is unpublished" do
    configure_email!
    reservation_email_templates(:pickup_reminder_email).unpublish!
    sign_in

    assert_no_enqueued_jobs do
      post send_pickup_reminder_emails_admin_reservations_url
    end

    assert_redirected_to admin_reservations_url
    assert_equal "Pickup reminder email is not published. Edit the template and publish it before sending.", flash[:alert]
  end

  test "show displays whether the pickup reminder was sent" do
    reservation = reservations(:pending_pickup_1)
    reservation.update_column(:pickup_reminder_email_sent_at, Time.current)
    sign_in

    get admin_reservation_url(reservation)

    assert_response :success
    assert_select ".admin-detail dt", text: "Pickup reminder email"
    assert_select ".admin-badge", text: /Sent/
  end

  test "sends a pickup reminder test email from the reservations panel" do
    configure_email!
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false
    sign_in
    template = reservation_email_templates(:pickup_reminder_email)

    post send_test_admin_reservation_email_template_url(template), params: {
      email: "admin@example.com",
      source: "published",
      return_to: "reservations"
    }

    assert_redirected_to admin_reservations_url
    assert_equal "Test email sent to admin@example.com.", flash[:notice]
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
  end

  test "queues a pickup reminder email from the reservation show page" do
    configure_email!
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false
    sign_in
    reservation = reservations(:pending_pickup_not_routed)

    assert_enqueued_emails 1 do
      post send_pickup_reminder_email_admin_reservation_url(reservation)
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Pickup reminder email was queued for delivery to #{reservation.email}.", flash[:notice]
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
  end

  test "does not queue a pickup reminder that was already sent" do
    configure_email!
    sign_in
    reservation = reservations(:pending_pickup_not_routed)
    reservation.update_column(:pickup_reminder_email_sent_at, Time.current)

    assert_no_enqueued_emails do
      post send_pickup_reminder_email_admin_reservation_url(reservation)
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Pickup reminder email was already sent to #{reservation.email}.", flash[:alert]
  end

  test "includes the live reservation notification container" do
    sign_in
    get admin_reservations_url

    assert_response :success
    assert_select "#admin-notifications[aria-live='polite']"
    assert_select "turbo-cable-stream-source", minimum: 2
  end

  test "should get index with closed reservations" do
    Setting.instance.update(is_reservations_open: false)
    sign_in
    get admin_reservations_url
    assert_equal "Reservations are CLOSED.", flash[:alert]
  end

  test "should search reservations by name, email, or address" do
    sign_in
    get admin_reservations_url(q: "Icky")
    assert_response :success
    assert_match "Icky Jones", response.body
    assert_no_match "John Doe", response.body
  end

  test "should filter reservations by status" do
    sign_in
    get admin_reservations_url(status: "picked_up")
    assert_response :success
    assert_match "Bob Jones", response.body
    assert_no_match "Icky Jones", response.body
  end

  test "should filter reservations that need an address review" do
    sign_in
    reservable = reservations(:pending_pickup_1)
    reservable.update_columns(address_match_status: "unavailable")

    get admin_reservations_url(address_check: "needs_review")

    assert_response :success
    assert_match reservable.name, response.body
    assert_no_match reservations(:picked_up_1).name, response.body
  end

  test "should combine search with a status filter" do
    sign_in
    get admin_reservations_url(q: "Jones", status: "pending_pickup")
    assert_response :success
    assert_match "Mary Jones", response.body
    assert_no_match "Bob Jones", response.body
    assert_no_match "Icky Jones", response.body
  end

  test "should ignore an unknown status filter" do
    sign_in
    get admin_reservations_url(status: "bogus")
    assert_response :success
    assert_match "Icky Jones", response.body
    assert_match "Bob Jones", response.body
  end

  test "should sort reservations by created date" do
    sign_in
    get admin_reservations_url(sort: "created_at", direction: "asc")
    assert_response :success
    # The oldest fixture (Form Minimum) renders before the next-oldest (Bob Jones).
    assert_match(/Form Minimum.*Bob Jones/m, response.body)
  end

  test "should get show" do
    sign_in
    get admin_reservation_url(reservations(:pending_pickup_1))
    assert_response :success
    assert_select "form[action=?] select[name=?]", assign_route_admin_reservation_path(reservations(:pending_pickup_1)), "reservation[route_id]"
    assert_select "input[type=checkbox][name=?]", "reservation[is_missing_tree_notifications_enabled]"
  end

  test "show displays address verification details and a re-verify button" do
    sign_in
    reservation = reservations(:pending_pickup_1)
    reservation.update_columns(
      address_match_status: "unavailable",
      address_match_score: 0.42,
      submitted_address: "123 Main Street, New York, NY, United States",
      formatted_address: "123 Main Street, New York, NY 10001, United States"
    )

    get admin_reservation_url(reservation)

    assert_response :success
    assert_select ".admin-badge", text: "Needs review"
    assert_match "123 Main Street, New York, NY, United States", response.body
    assert_match "123 Main Street, New York, NY 10001, United States", response.body
    assert_select "form[action=?] button", verify_address_admin_reservation_path(reservation), text: "Re-verify Address"
  end

  test "should re-verify an address against the pickup area" do
    sign_in
    configure_address_verification!
    reservation = reservations(:routing_1)

    with_stubbed_location_search([ verified_address_result ]) do
      post verify_address_admin_reservation_url(reservation)
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Address verified for the pickup area.", flash[:notice]
    reservation.reload
    assert reservation.address_match_verified?
    assert reservation.geocoded?
  end

  test "re-verifying an out-of-area address records a failure" do
    sign_in
    configure_address_verification!
    reservation = reservations(:routing_1)
    out_of_area = verified_address_result(
      locality: "Seattle",
      region: "Washington",
      region_code: "WA",
      region_name: "Washington"
    )

    with_stubbed_location_search([ out_of_area ]) do
      post verify_address_admin_reservation_url(reservation)
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Address could not be verified for the pickup area. It will need manual routing.", flash[:alert]
    reservation.reload
    assert reservation.address_match_unavailable?
    assert_nil reservation.latitude
  end

  test "does not re-verify when routing is disabled" do
    sign_in
    Setting.instance.update!(is_routing_enabled: false)
    reservation = reservations(:routing_1)

    with_stubbed_location_search([ verified_address_result ]) do
      post verify_address_admin_reservation_url(reservation)
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Address verification requires automatic routing and Places v2.", flash[:alert]
    assert_nil reservation.reload.address_match_status
  end

  test "should get show with the reservation's logs" do
    sign_in
    get admin_reservation_url(reservations(:routing_1))

    assert_response :success
    assert_match logs(:reservation_status_change).message, response.body
    assert_select "section h2", text: "Reservation logs"
    assert_select "a[href=?]", admin_log_path(logs(:reservation_status_change)), text: "View"
  end

  test "should link to all logs when the reservation has more than ten logs" do
    sign_in
    reservation = reservations(:routing_1)
    11.times { |i| reservation.logs.create!(log_type: "reservation", severity: "info", message: "Log entry #{i}") }

    get admin_reservation_url(reservation)

    assert_response :success
    assert_match "Log entry 10", response.body
    assert_no_match "Log entry 0", response.body
    assert_select "a[href=?]", admin_logs_path(reservation_id: reservation.id), text: "View all reservation logs"
  end

  test "should get edit" do
    sign_in
    get edit_admin_reservation_url(reservations(:pending_pickup_1))
    assert_response :success
  end

  test "should get update" do
    sign_in
    patch admin_reservation_url(reservations(:pending_pickup_1)), params: { reservation: { name: "New Name" } }
    assert_redirected_to admin_reservation_url(reservations(:pending_pickup_1))
    assert_equal "Reservation was successfully updated.", flash[:notice]
  end

  test "should redirect back to the show page after a status update" do
    sign_in
    reservation = reservations(:pending_pickup_1)

    patch admin_reservation_url(reservation),
          params: { reservation: { status: "cancelled" } },
          headers: { "HTTP_REFERER" => admin_reservation_url(reservation) }

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "cancelled", reservation.reload.status
    assert_equal "Reservation was successfully updated.", flash[:notice]
  end

  test "should redirect to the show page after an update from the edit page" do
    sign_in
    reservation = reservations(:pending_pickup_1)

    patch admin_reservation_url(reservation),
          params: { reservation: { name: "New Name" } },
          headers: { "HTTP_REFERER" => edit_admin_reservation_url(reservation) }

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "New Name", reservation.reload.name
  end

  test "should toggle automated missing tree notifications" do
    sign_in
    reservation = reservations(:pending_pickup_1)

    patch admin_reservation_url(reservation),
          params: { reservation: { is_missing_tree_notifications_enabled: "0" } },
          headers: { "HTTP_REFERER" => admin_reservation_url(reservation) }

    assert_redirected_to admin_reservation_url(reservation)
    assert_not reservation.reload.is_missing_tree_notifications_enabled?

    patch admin_reservation_url(reservation),
          params: { reservation: { is_missing_tree_notifications_enabled: "1" } },
          headers: { "HTTP_REFERER" => admin_reservation_url(reservation) }

    assert reservation.reload.is_missing_tree_notifications_enabled?
  end

  test "should get destroy" do
    sign_in
    delete admin_reservation_url(reservations(:pending_pickup_1))
    assert_redirected_to admin_reservations_url
    assert_equal "Reservation was successfully deleted.", flash[:notice]
  end

  test "should show a route reservation button" do
    sign_in
    reservation = reservations(:pending_pickup_1)
    get admin_reservation_url(reservation)

    assert_select "form[action=?] button", route_admin_reservation_path(reservation), text: "Route reservation"
  end

  test "should queue a reservation for routing" do
    sign_in
    Setting.instance.update(is_routing_enabled: true)
    reservation = reservations(:pending_pickup_1)

    assert_enqueued_with(job: RouteReservationJob, args: [ reservation.id ]) do
      post route_admin_reservation_url(reservation)
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Reservation was queued for routing.", flash[:notice]
  end

  test "should not queue a reservation for routing when routing is disabled" do
    sign_in
    Setting.instance.update(is_routing_enabled: false)
    reservation = reservations(:pending_pickup_1)

    assert_no_enqueued_jobs do
      post route_admin_reservation_url(reservation)
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Routing is disabled", flash[:alert]
  end

  test "should indicate when a route was manually assigned" do
    sign_in

    get admin_reservation_url(reservations(:picked_up_2))
    assert_select ".admin-badge", text: "Manually assigned"

    get admin_reservation_url(reservations(:pending_pickup_1))
    assert_select ".admin-badge", text: "Manually assigned", count: 0
  end

  test "should manually assign a route" do
    sign_in
    reservation = reservations(:pending_pickup_1)

    patch assign_route_admin_reservation_url(reservation), params: { reservation: { route_id: routes(:two).id } }

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Reservation route was successfully updated.", flash[:notice]
    assert_equal routes(:two), reservation.reload.route
    assert reservation.is_manually_routed?
  end

  test "should clear a manually assigned route" do
    sign_in
    reservation = reservations(:pending_pickup_1)

    patch assign_route_admin_reservation_url(reservation), params: { reservation: { route_id: "" } }

    assert_redirected_to admin_reservation_url(reservation)
    assert_nil reservation.reload.route
    assert_equal "routing", reservation.status
  end

  test "geocode reports success only when coordinates are saved" do
    sign_in
    Setting.instance.update!(is_routing_enabled: true)
    configure_location_service!
    reservation = reservations(:routing_1)

    with_stubbed_geocoding do
      post geocode_admin_reservation_url(reservation)
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Reservation was successfully geocoded.", flash[:notice]
    assert reservation.reload.geocoded?
  end

  test "geocode reports a failure when the place index is blank" do
    sign_in
    Setting.instance.update!(is_routing_enabled: true)
    configure_location_service!
    Setting.instance.update!(aws_location_index_name: "")
    reservation = reservations(:routing_1)

    assert_difference -> { Log.where(log_type: "error", reservation_id: reservation.id).count }, 1 do
      post geocode_admin_reservation_url(reservation)
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Geocoding was not successful.", flash[:alert]
    assert_nil flash[:notice]
    assert_nil reservation.reload.latitude
    log = Log.where(log_type: "error", reservation_id: reservation.id).order(:created_at).last
    assert_equal ":index_name must not be blank", log.message
  end

  test "should route the address again after a manual route is removed" do
    sign_in
    Setting.instance.update(is_routing_enabled: true)
    configure_location_service!

    reservation = reservations(:routing_1)

    patch assign_route_admin_reservation_url(reservation), params: { reservation: { route_id: routes(:two).id } }
    assert reservation.reload.is_manually_routed?

    patch assign_route_admin_reservation_url(reservation), params: { reservation: { route_id: "" } }
    assert_nil reservation.reload.route
    assert_not reservation.is_manually_routed?

    clear_enqueued_jobs

    with_stubbed_geocoding do
      post route_admin_reservation_url(reservation)
      perform_enqueued_jobs
    end

    assert reservation.reload.route.present?
    assert_not reservation.is_manually_routed?
    assert reservation.was_automatically_routed?
  end

  test "should show send and resend buttons for each email type" do
    sign_in
    reservation = reservations(:pending_pickup_1)
    get admin_reservation_url(reservation)

    assert_select "form[action=?]", resend_email_admin_reservation_path(reservation), count: 3
    assert_select "input[name=kind][value=confirmation]"
    assert_select "input[name=kind][value=cancellation]"
    assert_select "input[name=kind][value=missing_tree]"
    assert_select "button[data-turbo-confirm]" do |buttons|
      assert buttons.any? { |button| button["data-turbo-confirm"].include?("was already sent") }
    end
  end

  test "should resend the confirmation email" do
    sign_in
    Setting.instance.update(is_emailing_enabled: true)
    reservation = reservations(:pending_pickup_1)

    assert_enqueued_emails 1 do
      post resend_email_admin_reservation_url(reservation), params: { kind: "confirmation" }
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Confirmation email was queued for delivery to #{reservation.email}.", flash[:notice]
  end

  test "should resend the cancellation email" do
    sign_in
    Setting.instance.update(is_emailing_enabled: true)
    reservation = reservations(:cancelled_1)

    assert_enqueued_emails 1 do
      post resend_email_admin_reservation_url(reservation), params: { kind: "cancellation" }
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Cancellation email was queued for delivery to #{reservation.email}.", flash[:notice]
  end

  test "should resend the missing tree email" do
    sign_in
    Setting.instance.update(is_emailing_enabled: true)
    reservation = reservations(:missing_1)

    assert_enqueued_emails 1 do
      post resend_email_admin_reservation_url(reservation), params: { kind: "missing_tree" }
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Missing tree email was queued for delivery to #{reservation.email}.", flash[:notice]
  end

  test "should not resend an unknown email type" do
    sign_in
    Setting.instance.update(is_emailing_enabled: true)
    reservation = reservations(:pending_pickup_1)

    assert_no_enqueued_emails do
      post resend_email_admin_reservation_url(reservation), params: { kind: "bogus" }
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Unknown email type.", flash[:alert]
  end

  test "should not resend an email when emailing is disabled" do
    sign_in
    Setting.instance.update(is_emailing_enabled: false)
    reservation = reservations(:pending_pickup_1)

    assert_no_enqueued_emails do
      post resend_email_admin_reservation_url(reservation), params: { kind: "confirmation" }
    end

    assert_redirected_to admin_reservation_url(reservation)
    assert_equal "Emailing is disabled. Enable it in Settings before sending emails.", flash[:alert]
  end
end
