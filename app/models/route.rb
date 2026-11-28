class Route < ApplicationRecord
  include Geocodable

  has_many :reservations, dependent: :nullify
  has_many :driver_routes, dependent: :destroy
  has_many :drivers, through: :driver_routes
  belongs_to :zone, optional: true
  has_many :points, dependent: :destroy

  validates :name, presence: true
  validates :name, length: { maximum: 40 }

  # Sides counted as shared when a point of one route lies this close to the
  # other route's boundary. Exact vertices match, and so do borders whose
  # corners were drawn a few meters apart, such as Battle Point and Meadowmeer.
  SHARED_BOUNDARY_METERS = 20

  scope :ordered, -> { order(:name) }
  scope :unzoned, -> { where(zone_id: nil) }

  # Routes that border this one: a point of either boundary is within
  # SHARED_BOUNDARY_METERS of the other boundary.
  def self.sharing_a_point_with(route)
    origin = boundary_coordinates(route)
    return none if origin.empty?

    ids = includes(:points).where.not(id: route.id).filter_map { |other|
      other.id if boundaries_approach?(origin, boundary_coordinates(other), SHARED_BOUNDARY_METERS)
    }
    where(id: ids).ordered
  end

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

  def self.boundary_coordinates(route)
    route.points.sort_by { |point| point.order.to_i }.filter_map do |point|
      next if point.latitude.blank? || point.longitude.blank?

      [ point.latitude.to_f, point.longitude.to_f ]
    end
  end

  def self.boundaries_approach?(origin, other, limit)
    return false if origin.empty? || other.empty?

    origin.any? { |point| near_boundary?(point, other, limit) } ||
      other.any? { |point| near_boundary?(point, origin, limit) }
  end

  def self.near_boundary?(point, boundary, limit)
    return true if boundary.any? { |other| distance_meters(point, other) <= limit }

    boundary_segments(boundary).any? { |segment| distance_to_segment(point, segment) <= limit }
  end

  def self.boundary_segments(coordinates)
    return [] if coordinates.size < 2

    segments = coordinates.each_cons(2).to_a
    segments << [ coordinates.last, coordinates.first ] if coordinates.size > 2
    segments
  end

  def self.distance_meters(from, to)
    latitude_meters = (from[0] - to[0]) * 111_000
    longitude_scale = 111_000 * Math.cos(from[0] * Math::PI / 180)
    longitude_meters = (from[1] - to[1]) * longitude_scale
    Math.hypot(latitude_meters, longitude_meters)
  end

  def self.distance_to_segment(point, segment)
    start_point, end_point = segment
    longitude_scale = 111_000 * Math.cos(start_point[0] * Math::PI / 180)
    end_x = (end_point[1] - start_point[1]) * longitude_scale
    end_y = (end_point[0] - start_point[0]) * 111_000
    point_x = (point[1] - start_point[1]) * longitude_scale
    point_y = (point[0] - start_point[0]) * 111_000
    length_squared = (end_x * end_x) + (end_y * end_y)
    return Math.hypot(point_x, point_y) if length_squared.zero?

    ratio = [ [ (point_x * end_x + point_y * end_y) / length_squared, 0 ].max, 1 ].min
    Math.hypot(point_x - (ratio * end_x), point_y - (ratio * end_y))
  end
  private_class_method :boundary_coordinates, :boundaries_approach?, :near_boundary?,
    :boundary_segments, :distance_meters, :distance_to_segment

  private

  def broadcast_pending_pickup_overview
    PendingPickupOverview.broadcast_update(route_ids: [ id ])
  end
end
