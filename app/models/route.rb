class Route < ApplicationRecord
  include Geocodable

  has_many :reservations, dependent: :nullify
  has_many :driver_routes, dependent: :destroy
  has_many :drivers, through: :driver_routes
  belongs_to :zone, optional: true
  has_many :points, dependent: :destroy

  validates :name, presence: true
  validates :name, length: { maximum: 40 }

  scope :ordered, -> { order(:name) }
  scope :unzoned, -> { where(zone_id: nil) }

  attribute :is_zoned, :boolean, default: true

  def name_with_zone
    (zone&.name || "No Zone") + " / " + self&.name
  end

  # def zone!
  #   Router.new(self).zone!
  # end

  def polygon?
    points.count > 3
  end

  # Reservations on this route still waiting to be picked up. Pickups on the
  # route are complete when none remain.
  def pending_pickup_count
    reservations.pending_pickup.count
  end

  # Pending and missing reservations, the stops still on a driver's list.
  def pickups
    if reservations.loaded?
      reservations.select { |reservation| reservation.pending_pickup? || reservation.missing? }
    else
      reservations.pickup
    end
  end

  def pickup_count
    if reservations.loaded?
      pickups.size
    else
      reservations.pickup.count
    end
  end

  def contains?(lat, lon)
    return false unless polygon?
    polygon_array = points.order(:order).map { |point| Geokit::LatLng.new(point.latitude, point.longitude) }
    polygon = Geokit::Polygon.new(polygon_array)
    point = Geokit::LatLng.new(lat, lon)
    polygon.contains?(point)
  end
end
