class Reservation < ApplicationRecord
  include Geocodable

  belongs_to :route, optional: true, counter_cache: true
  has_one :zone, through: :route
  has_many :donations, dependent: :nullify

  validates :name, :street, :email, :city, :state, :country, presence: true
  validates :email, uniqueness: true

  enum :status, { reservation_form: 0, address_verification: 1,  donation: 2, routing: 3, pending_pickup: 4, picked_up: 5, missing: 6, cancelled: 7 }, default: :reservation_form

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

  # reset geocoding data if address is changed
  before_save :reset_geocoding!, if: ->(obj) { obj.pending_pickup?  && (obj.saved_change_to_street? || obj.saved_change_to_city? || obj.saved_change_to_state? || obj.saved_change_to_zip?) }

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

  # reset geocoding data if it's geocoded
  def reset_geocoding!
    return unless is_geocoded?
    self.latitude = nil
    self.longitude = nil
    self.route_id = nil
    self.distance_to_route = nil
    self.was_geocoded = false
    self.status = "routing"
  end

  def destroy_not_active_reservations!
    not_active = Reservation.not_active.where(email: email)
    not_active.destroy_all if not_active.any?
  end

  # remove prior reservation if it exists
  def remove_prior_reservation!
    PriorReservation.where(email: email).destroy_all
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
end
