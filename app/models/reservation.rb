class Reservation < ApplicationRecord
  include Geocodable

  belongs_to :route, optional: true
  has_one :zone, through: :route
  has_many :donations, dependent: :nullify

  validates :name, :street, :email, :city, :state, presence: true
  validates :email, uniqueness: true

  enum :status, { reservation_form: 0, address_verification: 1,  donation_type_selection: 2, pending_pickup: 3,picked_up: 4, missing: 5, cancelled: 6 }, default: :reservation_form
  enum :donation, { online_donation: 1, cash_or_check_donation: 2, no_donation: 3 }

  attribute :city, :string, default: -> { Setting.instance.default_city }
  attribute :state, :string, default: -> { Setting.instance.default_state }
  attribute :country, :string, default: "United States"

  scope :active, -> { where(status: ['pending_pickup', 'picked_up', 'missing', 'cancelled'])}

  # data normalization
  normalizes :email, with: -> e { e.strip.downcase }
  normalizes :mobile, with: -> m { Phonelib.parse(m).full_e164.presence if m.present? }

  # destroy any related not pending reservations
  before_validation :destroy_not_pending_reservations!, if: -> (obj){ obj.reservation_form? && !obj.persisted? }

  # email delivery
  after_update :send_confirmed_reservation_email!, if: -> (obj){ obj.pending_pickup? && obj.saved_change_to_status? }
  after_update :send_cancelled_reservation_email!, if: -> (obj){ obj.cancelled? && obj.saved_change_to_status? }
  after_save :remove_prior_reservation!, if: -> (obj){ obj.pending_pickup? && obj.saved_change_to_status? }

  def self.open?
    Setting.instance.is_reservations_open?
  end

  def verify_address!
    nil
  end

  def suggested_address?
    nil
  end

  def destroy_not_pending_reservations!
    not_pending = Reservation.not_pending_pickup.where(email: email)
    not_pending.destroy_all if not_pending.any?
  end

  # remove prior reservation if it exists
  def remove_prior_reservation!
    PriorReservation.where(email: email).destroy_all
  end

  def send_confirmed_reservation_email!
    ReservationsMailer.with(reservation: self).new_reservation_email.deliver_later
  end

  def send_cancelled_reservation_email!
    ReservationsMailer.with(reservation: self).cancelled_reservation_email.deliver_later
  end

  def self.migrate_reservations!
    Reservation.active.each do |r|
      PriorReservation.where(email: r.email).destroy_all
      PriorReservation.create(email: r.email, name: r.name, mobile: r.mobile, street: r.street)
    end
    Reservation.destroy_all
  end

end
