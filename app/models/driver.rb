class Driver < ApplicationRecord
  has_many :driver_routes, dependent: :destroy
  has_many :routes, -> { order(:name) }, through: :driver_routes
  belongs_to :zone_leader_zone, class_name: "Zone", optional: true

  validates :name, :mobile, presence: true

  scope :zone_leaders, -> { where.not(zone_leader_zone_id: nil) }

  before_save :clear_previous_zone_leader, if: :zone_leader_zone_id?

  normalizes :mobile, with: ->(mobile) {
    Phonelib.parse(mobile, Setting.instance&.phone_default_country.presence || "US").full_e164.presence if mobile.present?
  }

  def national_mobile
    return if mobile.blank?

    Phonelib.parse(mobile).national.presence || mobile
  end

  def zone_leader?
    zone_leader_zone_id.present?
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

  private

  # Each zone has one leader. Clearing the previous leader for this zone
  # before saving keeps the partial unique index satisfied.
  def clear_previous_zone_leader
    Driver.where(zone_leader_zone_id: zone_leader_zone_id).where.not(id: id)
      .update_all(zone_leader_zone_id: nil)
  end
end
