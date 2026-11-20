# Pickup overview counts and plotted stops, shared by the pickups home
# page and a single zone page.
class PickupMap
  attr_reader :status_counts, :coordinate_less_counts

  def initialize(route_ids: nil)
    scope = Reservation.pickup_overview
    scope = scope.where(route_id: route_ids) unless route_ids.nil?

    @status_counts = scope.group(:route_id, :status).count
    @plotted_reservations = scope.where.not(latitude: nil, longitude: nil).includes(:route).to_a
    @coordinate_less_counts = scope.where("latitude IS NULL OR longitude IS NULL").group(:route_id).count
  end

  def plotted_reservations
    @plotted_reservations
  end

  def plotted_by_zone_id
    @plotted_by_zone_id ||= @plotted_reservations
      .select { |reservation| reservation.route&.zone_id }
      .group_by { |reservation| reservation.route.zone_id }
  end

  def unzoned_plotted
    @unzoned_plotted ||= @plotted_reservations.select { |reservation| reservation.route && reservation.route.zone_id.nil? }
  end
end
