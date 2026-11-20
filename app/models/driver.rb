class Driver < ApplicationRecord
  has_many :driver_routes, dependent: :destroy
  has_many :routes, -> { order(:name) }, through: :driver_routes

  validates :name, :mobile, presence: true

  normalizes :mobile, with: ->(mobile) {
    Phonelib.parse(mobile, Setting.instance&.phone_default_country.presence || "US").full_e164.presence if mobile.present?
  }

  def national_mobile
    return if mobile.blank?

    Phonelib.parse(mobile).national.presence || mobile
  end

  # Pending and missing reservations across this driver's routes. Uses
  # preloaded routes and reservations when the caller already includes them.
  def pickup_count
    if routes.loaded?
      routes.sum(&:pickup_count)
    else
      Reservation.pickup.where(route_id: route_ids).count
    end
  end
end
