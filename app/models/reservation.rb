# TODO Make sure that changing street, clearing route, clears coordinates, will reset was_automatically_geocoded/routedto false
class Reservation < ApplicationRecord
  include Geocodable

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

  EXPORT_FIELDS = [
    "name", "email", "mobile", "street", "unit", "city", "state", "zip", "country",
    "pickup_notes", "status", "donation_type", "latitude", "longitude", "route",
    "created_at", "updated_at"
  ].freeze

  DEFAULT_MISSING_TREE_SMS = "Hi there! We're having trouble finding your tree for pick-up. Maybe it's not out, or you might not need it picked up anymore. Let us know by replying to this ASAP if you would like us to attempt another pick-up of your tree. Thanks!"
  DEFAULT_MISSING_TREE_SMS_FOLLOW_UP = "Hello, we are still having trouble finding your tree for pickup. Please check that it's out and reply to this message confirming it's location if you want us to try again. Thanks!"

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
  validates :mobile, phone: { possible: true, allow_blank: true }

  scope :completed, -> { where(status: [ "routing", "pending_pickup", "picked_up", "missing", "cancelled" ]) }
  scope :not_completed, -> { where.not(status: [ "routing", "pending_pickup", "picked_up", "missing", "cancelled" ]) }
  scope :migratable, -> { where(status: [ "routing", "pending_pickup", "picked_up", "missing", "cancelled", "imported" ]) }
  scope :active, -> { where(status: [ "routing", "pending_pickup" ]) }
  scope :not_active, -> { where.not(status: [ "routing", "pending_pickup" ]) }
  scope :pickup, -> { where(status: [ "pending_pickup", "missing" ]) }
  scope :routing_ready, -> {
    routing.
    where(latitude: nil).
    or(Reservation.routing.where(longitude: nil)).
    or(Reservation.routing.where(route_id: nil))
  }

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

  def destroy_not_active_reservations!
    not_active = Reservation.not_active.where(email: email)
    not_active.destroy_all if not_active.any?
  end

  # remove contact if it exists
  def remove_contact!
    Contact.where(email: email).destroy_all
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
      Contact.where(email: r.email).destroy_all
      Contact.create(email: r.email, name: r.name, mobile: r.mobile, street: r.street)
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
    reset_routing!
  end

  def reset_routing!
    self.route_id = nil
    self.was_automatically_routed = false
    self.is_manually_routed = false
    self.status = "routing"
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
    when "created_at", "updated_at"
      reservation.public_send(field)&.iso8601
    else
      reservation.public_send(field)
    end
  end

  private
end
