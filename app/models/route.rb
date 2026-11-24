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

  # Routes for the selected driver come first, followed by routes with no
  # driver, then routes assigned only to other drivers. Each group is
  # alphabetical by name.
  def self.ordered_for_driver(driver)
    routes = ordered.to_a
    return routes unless driver

    assigned, rest = routes.partition { |route| route.drivers.any? { |route_driver| route_driver.id == driver.id } }
    unassigned, other_drivers = rest.partition { |route| route.drivers.empty? }
    assigned + unassigned + other_drivers
  end

  attribute :is_zoned, :boolean, default: true

  # Route names, zones, and additions/removals all change the pickups
  # overview grouping, so refresh the overview on any route change.
  after_commit :broadcast_pending_pickup_overview, on: [ :create, :update, :destroy ]

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

  private

  def broadcast_pending_pickup_overview
    PendingPickupOverview.broadcast_update(route_ids: [ id ])
  end
end
