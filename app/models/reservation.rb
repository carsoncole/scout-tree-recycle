# TODO Make sure that changing street, clearing route, clears coordinates, will reset was_automatically_geocoded/routedto false
class Reservation < ApplicationRecord
  include Geocodable

  belongs_to :route, optional: true, counter_cache: true
  has_one :zone, through: :route
  has_many :donations, dependent: :nullify

  enum :status, { reservation_form: 0, address_verification: 1,  donation: 2, routing: 3, pending_pickup: 4, picked_up: 5, missing: 6, cancelled: 7 }, default: :reservation_form
  enum :donation_type, { online_donation: 1, cash_or_check_donation: 2, no_donation: 3 }

  attribute :city, :string, default: -> { Setting.instance.default_city }
  attribute :state, :string, default: -> { Setting.instance.default_state }
  attribute :country, :string, default: "United States"

  validates :name, :street, :email, :city, :state, :country, presence: true
  validates :email, uniqueness: true
  validates :status, inclusion: { in: statuses.keys }

  scope :completed, -> { where(status: [ "routing", "pending_pickup", "picked_up", "missing", "cancelled" ]) }
  scope :not_completed, -> { where.not(status: [ "routing", "pending_pickup", "picked_up", "missing", "cancelled" ]) }
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
  normalizes :mobile, with: ->(m) { Phonelib.parse(m).full_e164.presence if m.present? }
  before_save :extract_street_name

  # destroy any same-email not pending reservations since they're not needed
  before_validation :destroy_not_active_reservations!, if: ->(obj) { obj.reservation_form? && !obj.persisted? }

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
  after_update :send_confirmed_reservation_email!, if: ->(obj) { (obj.routing? || obj.pending_pickup?) && obj.saved_change_to_status? }
  after_update :send_cancelled_reservation_email!, if: ->(obj) { obj.cancelled? && obj.saved_change_to_status? }

  # remove prior reservation if it exists
  after_save :remove_prior_reservation!, if: ->(obj) { obj.routing? && obj.saved_change_to_status? }

  after_commit :route_reservation!, if: ->(obj) { obj.routing? && obj.routing_status == "Pending" &&  Setting.instance.is_routing_enabled? }

  # class methods
  def self.open?
    Setting.instance.is_reservations_open?
  end

  def verify_address!
    nil
  end

  def suggested_address?
    nil
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

  # remove prior reservation if it exists
  def remove_prior_reservation!
    PriorReservation.where(email: email).destroy_all
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

  def self.migrate_reservations!
    Reservation.completed.each do |r|
      PriorReservation.where(email: r.email).destroy_all
      PriorReservation.create(email: r.email, name: r.name, mobile: r.mobile, street: r.street)
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

  def routing_status
    if route # Successfully routed
      route.name
    elsif status_lower_than?("routing") # Incomplete reservations
      "Incomplete"
    elsif routing_failed? || geocoding_failed?
      "Manual"
    elsif is_manually_routed? # Manual routing is required
      "Manual"
    elsif !Setting.instance.is_routing_enabled && routing? # Routing is disabled so manual routing is required
      "Manual"
    elsif Setting.instance.is_routing_enabled && routing?
      "Pending"
    elsif status_higher_than?("pending_pickup") && !route.present?
      "Route Missing"
    else
      "Unknown"
    end
  end

  def route_reservation!
    RouteReservationJob.perform_later(id)
  end


  private
end
