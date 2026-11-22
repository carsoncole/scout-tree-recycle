class Location < ApplicationRecord
  validates :name, presence: true
  validates :location_type, length: { maximum: 60 }, allow_nil: true
  validates :latitude, presence: true
  validates :longitude, presence: true

  scope :ordered, -> { order(:name) }

  # Locations that fall within any of the given routes' bounded areas.
  # Points are sorted in Ruby so preloaded route points (includes(:points))
  # are reused instead of triggering per-route queries.
  def self.within_routes(routes)
    polygons = Array(routes).filter_map do |route|
      points = route.points.sort_by(&:order).filter_map do |point|
        next if point.latitude.blank? || point.longitude.blank?

        Geokit::LatLng.new(point.latitude, point.longitude)
      end

      Geokit::Polygon.new(points) if points.length > 3
    end

    return none if polygons.empty?

    all.select do |location|
      point = Geokit::LatLng.new(location.latitude, location.longitude)
      polygons.any? { |polygon| polygon.contains?(point) }
    end
  end
end
