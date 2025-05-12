class Reservation < ApplicationRecord
  include Geocodable

  belongs_to :route, optional: true, counter_cache: true
  has_one :zone, through: :route
  has_many :donations, dependent: :nullify

  validates :name, :street, :email, :city, :state, :country, presence: true
  validates :email, uniqueness: true

  enum :status, { reservation_form: 0, address_verification: 1,  donation: 2, routing: 3, pending_pickup: 4, picked_up: 5, missing: 6, cancelled: 7 }, default: :reservation_form
  enum :donation_type, { online_donation: 1, cash_or_check_donation: 2, no_donation: 3 }

  attribute :city, :string, default: -> { Setting.instance.default_city }
  attribute :state, :string, default: -> { Setting.instance.default_state }
  attribute :country, :string, default: "United States"

  scope :completed, -> { where(status: [ "routing", "pending_pickup", "picked_up", "missing", "cancelled" ]) }
  scope :not_completed, -> { where.not(status: [ "routing", "pending_pickup", "picked_up", "missing", "cancelled" ]) }
  scope :active, -> { where(status: [ "routing", "pending_pickup" ]) }
  scope :not_active, -> { where.not(status: [ "routing", "pending_pickup" ]) }
  scope :pickup, -> { where(status: [ "pending_pickup", "missing" ]) }

  # data normalization
  normalizes :email, with: ->(e) { e.strip.downcase }
  normalizes :mobile, with: ->(m) { Phonelib.parse(m).full_e164.presence if m.present? }

  # destroy any same-email not pending reservations since they're not needed
  before_validation :destroy_not_active_reservations!, if: ->(obj) { obj.reservation_form? && !obj.persisted? }

  # remove prior reservation if it exists
  after_save :remove_prior_reservation!, if: ->(obj) { obj.routing? && obj.saved_change_to_status? }

  # GEOCODING and ROUTING callbacks
  # Automatic geocoding enabled since lat/long changed to either blank
  before_save :set_not_manually_geocoded!, if: ->(obj) {obj.persisted? && (obj.routing? || obj.pending_pickup?) && (obj.will_save_change_to_latitude? || obj.will_save_change_to_longitude?) && (obj.latitude.blank? || obj.longitude.blank?) }

  # Manual geocoding enabled since lat/long changed (not blank)
  before_save :set_is_manually_geocoded!, if: ->(obj) { obj.persisted? && (obj.routing? || obj.pending_pickup?) && (obj.will_save_change_to_latitude? || obj.will_save_change_to_longitude?) && obj.latitude.present? && obj.longitude.present? }

  # Manual routing disabled since route removed
  before_save :set_not_manually_routed!, if: ->(obj) { obj.persisted? && obj.will_save_change_to_route_id? && obj.route_id.blank? }
  
  # Manual routing enabled since route manually set
  before_save :set_is_manually_routed!, if: ->(obj) { obj.persisted? && obj.will_save_change_to_route_id? && obj.route_id.present? }

  
  before_save :extract_street_name

  # reset status if route changes made
  before_save :reset_status_to_routing_if_route_removed!, if: ->(obj) { obj.pending_pickup? && obj.route_id.blank? }
  before_save :reset_status_to_pending_pickup_if_route_added!, if: ->(obj) { obj.routing? && obj.route_id.present? }

  # emails on confirmation and cancellation
  after_update :send_confirmed_reservation_email!, if: ->(obj) { obj.routing? && obj.saved_change_to_status? }
  after_update :send_cancelled_reservation_email!, if: ->(obj) { obj.cancelled? && obj.saved_change_to_status? }

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

  def manual_routing_required?
    routing_status == "Manual" ? true : false
  end

  def routing_status
    if route
      route.name
    elsif Setting.instance.is_routing_enabled == false
      "Manual"
    elsif Setting.instance.is_routing_enabled && is_manually_routed? && was_automatically_geocoded == false
      "Pending"
    else
      "Manual"
    end
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

  def reset_routing!
    # self.status = "routing"
    # self.route_id = nil
    # self.distance_to_route = nil
    # self.was_geocoded = false
    # self.route_id = nil
    # update_columns(status: "routing", route_id: nil, distance_to_route: nil, was_automatically_geocoded: false, route_id: nil)
  end

  def set_is_manually_geocoded!
    self.is_manually_geocoded = true
    self.was_automatically_geocoded = false
    self.route_id = nil
    self.status = "routing"
  end

  def set_not_manually_geocoded!
    self.is_manually_geocoded = false
    self.was_automatically_geocoded = false
    reset_geocoding!
    self.status = "routing"
  end

  def set_is_manually_routed!
    self.is_manually_routed = true
    self.was_automatically_routed = false
  end

  def set_not_manually_routed!
    self.is_manually_routed = false
    self.was_automatically_routed = false
  end

  def reset_geocoding!
    return if is_manually_geocoded?
    self.latitude = nil
    self.longitude = nil
    self.route_id = nil
    self.distance_to_route = nil
    self.was_automatically_geocoded = false
  end


  def extract_street_name
    # Extract everything after the initial number and optional space(s)
    self.street_name = street.sub(/^\d+\s*/, '')
  end
end
