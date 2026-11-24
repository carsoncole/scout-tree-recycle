# Remaining pending pickups grouped by zone and route. Powers the compact
# status overview on the admin pickups index. Picked up and missing
# reservations are excluded; only stops still waiting for pickup are counted.
class PendingPickupOverview
  STREAM = "admin_pending_pickups".freeze

  Row = Struct.new(:label, :route, :pending_count, keyword_init: true)
  Group = Struct.new(:label, :zone, :rows, :pending_count, :unrouted, keyword_init: true)

  # Replaces the overview on every open pickups page. Route ids passed in are
  # highlighted briefly by the pending-overview Stimulus controller.
  def self.broadcast_update(route_ids: [])
    Turbo::StreamsChannel.broadcast_replace_to(
      STREAM,
      target: "pending-overview",
      partial: "admin/pickups/pending_overview",
      locals: { pending_overview: new, updated_route_ids: Array(route_ids).uniq }
    )
  rescue StandardError => e
    Rails.logger.error("Pending pickup overview broadcast failed: #{e.class}: #{e.message}")
  end

  def initialize(scope = Reservation.pending_pickup)
    @counts = scope.group(:route_id).count
  end

  def total
    @counts.values.sum
  end

  def unrouted_count
    @counts.fetch(nil, 0)
  end

  # Routes grouped by zone (zoned zones first, then unzoned routes), followed
  # by pending reservations that have no route at all.
  def groups
    @groups ||= zone_groups.tap do |groups|
      groups << unrouted_group if unrouted_count.positive?
    end
  end

  # Widest bar on the chart. Every bar is scaled against this so route lengths
  # are comparable across zones.
  def max_count
    @max_count ||= groups.flat_map(&:rows).map(&:pending_count).max.to_i
  end

  # Percentage width for a bar. Non-zero counts keep a small minimum so a
  # single pickup next to a busy route is still visible.
  def bar_percent(count)
    return 0 if count.to_i <= 0 || max_count.zero?

    [ (count.to_f / max_count * 100).round, 4 ].max
  end

  private

  def zone_groups
    Route.includes(:zone).ordered.group_by(&:zone).map do |zone, routes|
      rows = routes.map do |route|
        Row.new(label: route.name, route: route, pending_count: @counts.fetch(route.id, 0))
      end

      Group.new(
        label: zone&.name || "No zone",
        zone: zone,
        rows: rows,
        pending_count: rows.sum(&:pending_count),
        unrouted: false
      )
    end.sort_by { |group| [ group.zone ? 0 : 1, group.label ] }
  end

  def unrouted_group
    Group.new(
      label: "Unrouted",
      zone: nil,
      rows: [ Row.new(label: "Pickups without a route", route: nil, pending_count: unrouted_count) ],
      pending_count: unrouted_count,
      unrouted: true
    )
  end
end
