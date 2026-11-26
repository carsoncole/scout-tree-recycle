# TODO Make sure that changing street, clearing route, clears coordinates, will reset was_automatically_geocoded/routedto false
class Reservation < ApplicationRecord
  include Geocodable
  include Mails::Correspondable

  attr_accessor :importing

  IMPORTABLE_FIELDS = {
    "name" => "Name",
    "email" => "Email",
    "mobile" => "Mobile",
    "street" => "Street",
    "unit" => "Unit",
    "city" => "City",
    "state" => "State",
    "zip" => "ZIP",
    "country" => "Country",
    "pickup_notes" => "Pickup notes",
    "status" => "Status",
    "donation_type" => "Donation type",
    "latitude" => "Latitude",
    "longitude" => "Longitude"
  }.freeze

  IMPORTABLE_FIELD_ALIASES = {
    "name" => %w[full_name customer_name customer],
    "email" => %w[email_address e_mail],
    "mobile" => %w[phone phone_number mobile_phone cell cell_phone],
    "street" => %w[address street_address pickup_address],
    "unit" => %w[apt apartment suite],
    "city" => %w[town],
    "state" => %w[province],
    "zip" => %w[zip_code postal_code postcode],
    "pickup_notes" => %w[notes comments],
    "donation_type" => %w[donation],
    "route" => %w[route_name]
  }.freeze

  # Every column of the reservations table (in schema order), plus the
  # associated route's name, so the CSV export is an exact copy of the table.
  EXPORT_FIELDS = [
    "id",
    "name", "email", "mobile",
    "street", "house_number", "street_name",
    "city", "state", "zip", "country",
    "pickup_notes",
    "donation_type", "stripe_charge_amount",
    "latitude", "longitude",
    "is_manually_geocoded", "was_automatically_geocoded",
    "is_manually_routed", "was_automatically_routed",
    "route_id", "route", "distance_to_route",
    "status", "heard_about_source", "unit",
    "is_door_hanger", "is_route_polygon",
    "confirmed_reservation_email_sent_at",
    "cancelled_reservation_email_sent_at",
    "missing_tree_email_sent_at", "missing_tree_sms_sent_at",
    "is_missing_tree_notifications_enabled",
    "created_at", "updated_at",
    "address_match_status", "address_match_score", "address_verified_at",
    "geo_place_id", "formatted_address", "submitted_address",
    "suggested_street", "suggested_city", "suggested_state", "suggested_zip",
    "suggested_country"
  ].freeze

  # Timestamp columns rendered as ISO 8601 strings in the CSV export.
  EXPORT_TIMESTAMP_FIELDS = %w[
    confirmed_reservation_email_sent_at
    cancelled_reservation_email_sent_at
    missing_tree_email_sent_at
    missing_tree_sms_sent_at
    created_at
    updated_at
    address_verified_at
  ].freeze

  DEFAULT_MISSING_TREE_SMS = "Hi there! We're having trouble finding your tree for pick-up. Maybe it's not out, or you might not need it picked up anymore. Let us know by replying to this ASAP if you would like us to attempt another pick-up of your tree. Thanks!"
  DEFAULT_MISSING_TREE_SMS_FOLLOW_UP = "Hello, we are still having trouble finding your tree for pickup. Please check that it's out and reply to this message confirming it's location if you want us to try again. Thanks!"

  # suggested and overridden remain valid for reservations created before
  # verification became a silent in-area check.
  ADDRESS_MATCH_STATUSES = %w[verified suggested overridden unavailable].freeze

  # Emails admins can send (or resend) from a reservation's email history.
  EMAIL_KINDS = {
    "confirmation" => {
      label: "Confirmation email",
      sent_at: :confirmed_reservation_email_sent_at,
      mailer: :new_reservation_email
    },
    "cancellation" => {
      label: "Cancellation email",
      sent_at: :cancelled_reservation_email_sent_at,
      mailer: :cancelled_reservation_email
    },
    "missing_tree" => {
      label: "Missing tree email",
      sent_at: :missing_tree_email_sent_at,
      mailer: :missing_tree_email
    }
  }.freeze

  belongs_to :route, optional: true, counter_cache: true
  has_one :zone, through: :route
  has_many :donations, dependent: :nullify
  # Activity logs survive reservation deletion but are detached from it.
  has_many :logs, dependent: :nullify

  enum :status, { reservation_form: 0, address_verification: 1, donation: 2, routing: 3, pending_pickup: 4, picked_up: 5, missing: 6, cancelled: 7, imported: 8 }, default: :reservation_form
  enum :donation_type, { online_donation: 1, cash_or_check_donation: 2, no_donation: 3 }

  # Signed, unguessable token for the reservation holder's public pages
  # (address verification, donation, confirmation, edit, and cancel). Emailed
  # links and flow redirects carry this token instead of the record id so
  # public pages cannot be reached by guessing ids.
  generates_token_for :public_access

  attribute :city, :string, default: -> { Setting.instance.default_city }
  attribute :state, :string, default: -> { Setting.instance.default_state }
  attribute :country, :string, default: -> { Setting.instance&.default_country.presence || "United States" }



  validates :name, :street, :email, :city, :state, :country, presence: true
  validates :email, uniqueness: true
  validates :status, inclusion: { in: statuses.keys }
  validates :address_match_status, inclusion: { in: ADDRESS_MATCH_STATUSES }, allow_nil: true
  validates :mobile, phone: { possible: true, allow_blank: true }

  # Statuses counted on the pickups overview and driver route pages.
  PICKUP_OVERVIEW_STATUSES = %w[pending_pickup picked_up missing].freeze

  scope :completed, -> { where(status: [ "routing", "pending_pickup", "picked_up", "missing", "cancelled" ]) }
  scope :pickup_overview, -> { where(status: PICKUP_OVERVIEW_STATUSES) }
  scope :not_completed, -> { where.not(status: [ "routing", "pending_pickup", "picked_up", "missing", "cancelled" ]) }
  # Admin search across contact and address columns. Matches a
  # case-insensitive substring of name, email, street, street name, or city.
  scope :search, ->(query) {
    next if query.blank?

    pattern = "%#{query.to_s.strip}%"
    where(
      "reservations.name ILIKE :pattern OR reservations.email ILIKE :pattern OR " \
      "reservations.street ILIKE :pattern OR reservations.street_name ILIKE :pattern OR " \
      "reservations.city ILIKE :pattern",
      pattern: pattern
    )
  }

  ADMIN_SORT_COLUMNS = {
    "name" => :name,
    "email" => :email,
    "address" => :street_name,
    "status" => :status,
    "created_at" => :created_at
  }.freeze

  # Admin reservations table: sort, optional status, and search. An unknown
  # sort falls back to newest first. An unknown status is ignored.
  def self.for_admin_index(sort:, direction:, status: nil, query: nil, address_check: nil)
    relation = includes(:route)
    relation = admin_sorted(relation, sort, direction)
    relation = relation.where(status: status) if status.present? && statuses.key?(status.to_s)
    relation = relation.needs_address_review if address_check == "needs_review"
    relation = relation.search(query) if query.present?
    relation
  end

  def self.admin_sorted(relation, sort, direction)
    return relation.order(created_at: :desc) unless ADMIN_SORT_COLUMNS.key?(sort.to_s) || sort.to_s == "route"

    sort_direction = direction.to_s == "desc" ? :desc : :asc
    if sort.to_s == "route"
      relation.joins(:route).order("routes.name" => sort_direction)
    else
      relation.order(ADMIN_SORT_COLUMNS.fetch(sort.to_s) => sort_direction)
    end
  end
  private_class_method :admin_sorted

  # Statuses copied into contacts when an event is closed. Every reservation
  # is deleted afterward, including statuses that are not in this list.
  MIGRATABLE_STATUSES = %w[routing pending_pickup picked_up missing cancelled imported].freeze
  scope :migratable, -> { where(status: MIGRATABLE_STATUSES) }
  scope :active, -> { where(status: [ "routing", "pending_pickup" ]) }
  scope :not_active, -> { where.not(status: [ "routing", "pending_pickup" ]) }
  scope :pickup, -> { where(status: [ "pending_pickup", "missing" ]) }
  scope :routing_ready, -> {
    routing.
    where(latitude: nil).
    or(Reservation.routing.where(longitude: nil)).
    or(Reservation.routing.where(route_id: nil))
  }

  # Reservations an organizer should look at before pickup day. Includes both
  # failed submit-time checks and routed reservations with no usable coords.
  scope :needs_address_review, -> {
    active = where.not(status: %w[cancelled imported])
    active.where(address_match_status: "unavailable").
      or(active.where(status: %w[routing pending_pickup], latitude: nil))
  }

  # Orders reservations by street address for the operational pickups pages.
  scope :ordered_by_street_address, -> { order(:street) }

  # Pending pickup reservations grouped by route for the driver report.
  # Returns an ordered array of [route, reservations] pairs, sorted by route
  # name. Unrouted reservations, if any, are grouped under nil and listed last.
  def self.pending_pickups_by_route
    grouped = pending_pickup.includes(route: [ :zone, :drivers, :points ]).ordered_by_street_address.group_by(&:route)

    grouped.keys.compact.sort_by(&:name)
      .map { |route| [ route, grouped[route] ] }
      .concat(grouped[nil] ? [ [ nil, grouped[nil] ] ] : [])
  end

  # data normalization
  normalizes :email, with: ->(e) { e.strip.downcase }
  normalizes :mobile, with: ->(m) { Phonelib.parse(m, Setting.instance&.phone_default_country.presence || "US").full_e164.presence if m.present? }
  before_save :extract_street_name

  # destroy any same-email not pending reservations since they're not needed
  before_validation :destroy_not_active_reservations!, if: ->(obj) { obj.reservation_form? && !obj.persisted? && !obj.importing }

  # GEOCODING and ROUTING callbacks

  # Reset geocoding if lat/long changed, and geocoding is not complete => reset geocoding
  before_save :reset_geocoding!, if: ->(obj) {
    obj.persisted? &&
    (((
      obj.will_save_change_to_latitude? ||
      obj.will_save_change_to_longitude?
      ) &&
      !obj.geocoded?
      ) ||
      obj.will_save_change_to_street?) }

  # Route removed => reset routing
  before_save :reset_routing!, if: ->(obj) {
    obj.persisted? &&
    obj.will_save_change_to_route_id? && obj.route_id.blank? }

  # Set manual geocoding, as manual lat/long en                                                                                                                                                 tered => manual geocoding
  before_save :set_is_manually_geocoded!, if: ->(obj) {
    obj.persisted? &&
    (obj.will_save_change_to_latitude? || obj.will_save_change_to_longitude?) &&
    obj.geocoded? }

  # Route set => manual routing
  before_save :set_is_manually_routed!, if: ->(obj) {
    obj.persisted? &&
    obj.will_save_change_to_route_id? && obj.route_id.present? }

  # reset status if route changes made
  before_save :reset_status_to_routing_if_route_removed!, if: ->(obj) { obj.pending_pickup? && obj.route_id.blank? }
  before_save :reset_status_to_pending_pickup_if_route_added!, if: ->(obj) { obj.routing? && obj.route_id.present? }

  # emails on confirmation and cancellation
  after_update :send_confirmed_reservation_email!, if: ->(obj) { (obj.routing? || obj.pending_pickup?) && obj.saved_change_to_status? && !obj.importing }
  after_update :send_cancelled_reservation_email!, if: ->(obj) { obj.cancelled? && obj.saved_change_to_status? && !obj.importing }

  # remove contact if it exists
  after_save :remove_contact!, if: ->(obj) { obj.routing? && obj.saved_change_to_status? && !obj.importing }

  after_commit :route_reservation!, if: ->(obj) { obj.routing? && obj.routing_status == "Pending" && Setting.instance&.is_routing_enabled? && !obj.importing }

  # missing tree reminder
  after_commit :send_missing_sms!, if: ->(obj) { obj.missing? && obj.is_missing_tree_notifications_enabled? && obj.mobile.present? && obj.saved_change_to_status? && obj.persisted? && !obj.importing }
  after_commit :send_missing_email!, if: ->(obj) { obj.missing? && obj.is_missing_tree_notifications_enabled? && !obj.mobile.present? && obj.saved_change_to_status? && obj.persisted? && !obj.importing }

  # Keep the admin pickups overview live when a stop moves on or off a route.
  # Router writes with update_columns, so it broadcasts separately.
  after_commit :broadcast_pending_pickup_overview, on: [ :create, :update, :destroy ]

  # Send one delayed notification so automatic routing has time to assign a
  # route before open admin pages are notified.
  after_create_commit :schedule_admin_reservation_notification, unless: :importing

  # RESERVATION ACTIVITY LOGS
  # Records a reservation log whenever a reservation is created or its
  # status changes, and a donation log when a cash/check donation is made
  # (cash/check is recorded on the reservation itself; online payments are
  # logged by Donation when Stripe confirms payment). Skipped while
  # importing.
  after_create :log_creation!, unless: :importing
  after_update :log_status_change!, if: ->(obj) { obj.saved_change_to_status? && !obj.importing }
  after_update :log_donation_type_change!, if: ->(obj) { obj.saved_change_to_donation_type? && !obj.importing }

  # class methods
  def self.open?
    Setting.instance&.is_reservations_open? || false
  end

  # Finds a reservation from a public URL token. Raises RecordNotFound for
  # invalid tokens and for guessable ids, so the public flow pages can only
  # be reached with a token from the reservation email or a flow redirect.
  def self.find_by_public_token!(token)
    find_by_token_for(:public_access, token.to_s) or raise ActiveRecord::RecordNotFound
  end

  def routed?
    route.present?
  end

  def route!
    Router.new(self).route!
  end

  def address_match_verified?
    address_match_status == "verified"
  end

  def address_match_unavailable?
    address_match_status == "unavailable"
  end

  # Checks the submitted street against the configured pickup city/state/
  # country. A match stores coordinates and continues silently. A miss or an
  # out-of-area match leaves the reservation without coordinates so the routing
  # job can retry and, if it still fails, flag the address for manual routing.
  def verify_address!
    return false unless persisted?

    submitted = address
    setting = Setting.instance

    unless setting&.address_verification_available?
      return unavailable_address_verification!(submitted)
    end

    results = LocationSearch.new(setting).geocode(submitted)
    result = preferred_geocode_result(results.select { |candidate| geocode_result_in_pickup_area?(candidate) })

    unless result&.coordinates
      return unavailable_address_verification!(submitted)
    end

    update_columns(
      address_match_status: "verified",
      address_match_score: result.match_score,
      address_verified_at: Time.current,
      geo_place_id: result.place_id,
      formatted_address: result.label,
      submitted_address: submitted,
      latitude: result.latitude,
      longitude: result.longitude,
      was_automatically_geocoded: true
    )

    true
  rescue LocationSearch::Error => error
    log_location_service_error(error)
    unavailable_address_verification!(submitted)
  end

  def destroy_not_active_reservations!
    not_active = Reservation.not_active.where(email: email)
    not_active.destroy_all if not_active.any?
  end

  # remove contact if it exists
  def remove_contact!
    Contact.marketing_subscribed.where(email: email).destroy_all
  end

  def reset_status_to_routing_if_route_removed!
    self.status = "routing" if route_id.blank?
  end

  def reset_status_to_pending_pickup_if_route_added!
    self.status = "pending_pickup" if route_id.present?
  end

  def send_confirmed_reservation_email!
    ReservationsMailer.with(reservation_id: id).new_reservation_email.deliver_later
  end

  def send_cancelled_reservation_email!
    ReservationsMailer.with(reservation_id: id).cancelled_reservation_email.deliver_later
  end

  def resend_email!(kind)
    config = EMAIL_KINDS[kind.to_s]
    raise ArgumentError, "Unknown email kind: #{kind}" unless config

    ReservationsMailer.with(reservation_id: id).public_send(config[:mailer], force: true).deliver_later
  end

  # Stable signed token used to build the reservation holder's public URLs.
  def public_token
    @public_token ||= generate_token_for(:public_access)
  end

  def self.migrate_reservations!
    Reservation.migratable.each do |r|
      contact = Contact.find_by(email: r.email)
      unsubscribed = contact&.is_unsubscribed_from_marketing? || false
      unsubscribed_at = contact&.unsubscribed_at
      Contact.where(email: r.email).destroy_all
      Contact.create(email: r.email, name: r.name, mobile: r.mobile, street: r.street, is_unsubscribed_from_marketing: unsubscribed, unsubscribed_at: unsubscribed_at)
    end
    Reservation.destroy_all
  end

  def set_is_manually_geocoded!
    self.is_manually_geocoded = true
    self.was_automatically_geocoded = false
    reset_routing!
  end

  def set_is_manually_routed!
    self.is_manually_routed = true
    self.was_automatically_routed = false
  end

  def reset_geocoding!
    self.latitude = nil
    self.longitude = nil
    self.route_id = nil
    self.distance_to_route = nil
    self.was_automatically_geocoded = false
    self.is_manually_geocoded = false
    self.address_match_status = nil
    self.address_match_score = nil
    self.address_verified_at = nil
    self.geo_place_id = nil
    self.formatted_address = nil
    self.submitted_address = nil
    self.suggested_street = nil
    self.suggested_city = nil
    self.suggested_state = nil
    self.suggested_zip = nil
    self.suggested_country = nil
    reset_routing!
  end

  def reset_routing!
    self.route_id = nil
    self.was_automatically_routed = false
    self.is_manually_routed = false
    # A cancelled reservation stays cancelled. Clearing its route must not
    # put it back into routing or send a new confirmation email.
    return if cancelled?

    # Only completed reservations (routing or later) reset to routing for
    # re-geocoding/re-routing. Incomplete reservations keep their flow
    # step; the flow itself promotes them to routing at completion.
    self.status = "routing" unless status_lower_than?("routing")
  end

  def extract_street_name
    # Extract everything after the initial number and optional space(s)
    self.street_name = street.sub(/^\d+\s*/, "")
  end

  def status_lower_than?(other_status)
    return false unless other_status.is_a?(String) && self.class.statuses.key?(other_status)
    self.class.statuses[status] < self.class.statuses[other_status]
  end

  def status_higher_than?(other_status)
    return false unless other_status.is_a?(String) && self.class.statuses.key?(other_status)
    self.class.statuses[status] > self.class.statuses[other_status]
  end

  def geocoding_failed?
    (latitude.blank? || longitude.blank?) && was_automatically_geocoded?
  end

  # Returns true if the reservation is pending pickup and the route is blank
  def routing_failed?
    route.blank? && was_automatically_routed?
  end

  def manual_routing_required?
    routing_status == "Manual" ? true : false
  end

  def summary
    "#{street}/#{status&.titleize}"
  end

  def routing_status
    return nil if imported?

    if route # Successfully routed
      route.name
    elsif status_lower_than?("routing") # Incomplete reservations
      "Incomplete"
    elsif routing_failed? || geocoding_failed?
      "Manual"
    elsif is_manually_routed? # Manual routing is required
      "Manual"
    elsif !Setting.instance&.is_routing_enabled && routing? # Routing is disabled so manual routing is required
      "Manual"
    elsif Setting.instance&.is_routing_enabled && routing?
      "Pending"
    elsif status_higher_than?("pending_pickup") && !route.present?
      "Route Missing"
    else
      "Unknown"
    end
  end

  def send_missing_sms!
    return unless is_missing_tree_notifications_enabled?
    return if self.mobile.blank?
    setting = Setting.instance
    message = if self.missing_tree_sms_sent_at.blank?
      setting&.missing_tree_sms_message.presence || DEFAULT_MISSING_TREE_SMS
    else
      setting&.missing_tree_sms_follow_up_message.presence || DEFAULT_MISSING_TREE_SMS_FOLLOW_UP
    end

    sms = Sms.create(
      body: message,
      phone: mobile,
      direction: "outgoing",
      user: Current.user
      )
    self.update(missing_tree_sms_sent_at: Time.current)
  end

  def send_missing_email!(override = false)
    return unless is_missing_tree_notifications_enabled?
    return if self.mobile.present?
    ReservationsMailer.with(reservation_id: self.id).missing_tree_email.deliver_later
  end

  def route_reservation!
    RouteReservationJob.perform_later(id)
  end


  def self.to_csv
    require "csv"

    CSV.generate(headers: EXPORT_FIELDS, write_headers: true) do |csv|
      includes(:route).find_each do |reservation|
        csv << EXPORT_FIELDS.map { |field| csv_value(reservation, field) }
      end
    end
  end

  def self.csv_value(reservation, field)
    case field
    when "route"
      reservation.route&.name
    when *EXPORT_TIMESTAMP_FIELDS
      reservation.public_send(field)&.iso8601
    else
      reservation.public_send(field)
    end
  end

  private

  # Places v2 Geocode results include city/state/country components. Require
  # them to match the reservation's pickup area, which public forms take from
  # Setting. Legacy results keep the existing behavior until Places v1 is
  # removed.
  def geocode_result_in_pickup_area?(result)
    return true unless result.is_a?(LocationSearch::Result)

    address_component_matches?(result.locality, city) &&
      address_component_matches?([ result.region_code, result.region_name ], state) &&
      address_component_matches?([ result.country, result.country_code ], country)
  end

  def address_component_matches?(actual, expected)
    expected = normalize_address_component(expected)
    return true if expected.blank?

    Array(actual).compact_blank.map { |value| normalize_address_component(value) }.include?(expected)
  end

  def normalize_address_component(value)
    value.to_s.downcase.gsub(/[^a-z0-9]+/, " ").squish
  end

  def unavailable_address_verification!(submitted)
    update_columns(
      address_match_status: "unavailable",
      address_match_score: nil,
      address_verified_at: nil,
      geo_place_id: nil,
      formatted_address: nil,
      submitted_address: submitted,
      suggested_street: nil,
      suggested_city: nil,
      suggested_state: nil,
      suggested_zip: nil,
      suggested_country: nil
    )
    false
  end

  def log_creation!
    record_activity_log!(
      log_type: "reservation",
      message: "Reservation created: #{name} (#{email}) — #{short_address}",
      context: { status: status }
    )
  end

  def log_status_change!
    from_status, to_status = saved_change_to_status
    record_activity_log!(
      log_type: "reservation",
      message: "Reservation status changed: #{from_status.presence || "none"} → #{to_status} — #{name} (#{email})",
      context: { from: from_status, to: to_status }
    )
  end

  def log_donation_type_change!
    from_type, to_type = saved_change_to_donation_type
    if to_type == "cash_or_check_donation"
      record_activity_log!(
        log_type: "donation",
        message: "Cash or check donation made — #{name} (#{email})",
        context: { from: from_type, to: to_type }
      )
    else
      record_activity_log!(
        log_type: "reservation",
        message: "Reservation donation changed: #{from_type.presence || "none"} → #{to_type&.humanize} — #{name} (#{email})",
        context: { from: from_type, to: to_type }
      )
    end
  end

  # Writes an activity log associated with this reservation. A logging
  # failure must never break the reservation save, so errors are reported
  # to the Rails logger instead of being raised.
  def record_activity_log!(log_type:, message:, context:)
    Log.create(
      log_type: log_type,
      reservation: self,
      message: message,
      context: context
    )
  rescue StandardError => e
    Rails.logger.error("Reservation activity could not be logged: #{e.class}: #{e.message}")
  end

  def schedule_admin_reservation_notification
    AdminReservationNotificationJob.set(wait: 10.seconds).perform_later(id)
  end

  # Broadcasts the route(s) this reservation just left or joined so the
  # pickups overview can refresh and briefly highlight them.
  def broadcast_pending_pickup_overview
    previous_status, current_status = saved_change_to_status || [ nil, status ]
    return unless [ previous_status, current_status ].include?("pending_pickup")

    previous_route_id, current_route_id = saved_change_to_route_id || [ route_id, route_id ]
    route_ids = []
    route_ids << previous_route_id if previous_status == "pending_pickup"
    route_ids << current_route_id if current_status == "pending_pickup"

    PendingPickupOverview.broadcast_update(route_ids: route_ids.uniq)
  end
end
