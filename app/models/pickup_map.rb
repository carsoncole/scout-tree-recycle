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

  # Pending / picked / missing / total counts across every route, including
  # reservations with no route.
  def status_totals
    @status_totals ||= Reservation::PICKUP_OVERVIEW_STATUSES.index_with(0).tap do |totals|
      status_counts.each do |(_route_id, status), count|
        totals[status] += count if totals.key?(status)
      end
      totals["total"] = totals.values.sum
    end
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
