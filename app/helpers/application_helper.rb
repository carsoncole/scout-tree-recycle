module ApplicationHelper
  def setting
    @setting ||= Setting.instance
  end

  # Single source of truth for the brand name in page titles. Matches the
  # header wordmark and the layout fallback so every tab reads the same.
  def default_page_name
    setting&.home_page_header.presence || setting&.organization_name.presence || "Tree Recycle"
  end

  # Shared event date and time formatting for the public pages so the
  # pickup details always read the same way everywhere.
  def pickup_full_date
    setting.event_pickup_start.strftime("%A, %B %-d, %Y")
  end

  def pickup_date
    setting.event_pickup_start.strftime("%B %-d, %Y")
  end

  def pickup_day
    setting.event_pickup_start.strftime("%A, %B %-d")
  end

  def pickup_start_time
    setting.event_pickup_start.strftime("%-l:%M%P")
  end

  def sign_up_deadline
    setting.event_sign_up_deadline.strftime("%B %-d, %Y at %-l:%M%P")
  end

  def external_link_icon(css_class: "size-3 shrink-0")
    tag.svg(
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": 1.8,
      class: css_class,
      aria: { hidden: true }
    ) do
      tag.path(
        d: "M7 17 17 7M9 7h8v8",
        "stroke-linecap": "round",
        "stroke-linejoin": "round"
      )
    end
  end

  # Small map pin marking a link that opens directions.
  def map_pin_icon(css_class: "size-4 shrink-0")
    tag.svg(
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": 1.8,
      "stroke-linecap": "round",
      "stroke-linejoin": "round",
      class: css_class,
      aria: { hidden: true }
    ) do
      tag.path(
        d: "M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm4.5-.5c-.375 6-4.5 9.75-7.5 12-3-2.25-7.125-6-7.5-12C4.5 5.25 8.25 1.5 12 1.5s7.5 3.75 7.5 8.5Z"
      )
    end
  end

  # Directions link for a pickup address. Geocoded reservations link their
  # plotted coordinates; reservations without coordinates fall back to the
  # full address string.
  def maps_directions_url(reservation)
    destination = if (coordinates = reservation.coordinates)
                    coordinates.join(",")
    else
                    [ reservation.street, reservation.unit.presence, reservation.city,
                      reservation.state, reservation.zip.presence, reservation.country ].compact_blank.join(", ")
    end

    maps_directions_url_for(destination)
  end

  # Directions for a named map location, which stores only coordinates.
  def location_directions_url(location)
    maps_directions_url_for([ location.latitude, location.longitude ].join(","))
  end

  # Apple devices open maps.apple.com links in the native Maps app with the
  # destination set; everything else gets a Google Maps directions URL.
  def maps_directions_url_for(destination)
    if apple_maps_device?
      "https://maps.apple.com/?daddr=#{ERB::Util.url_encode(destination)}"
    else
      "https://www.google.com/maps/dir/?api=1&destination=#{ERB::Util.url_encode(destination)}"
    end
  end

  # Apple devices (iPhone, iPad, iPod, Mac) open maps.apple.com links in the
  # native Maps app; other platforms do not.
  def apple_maps_device?
    request.user_agent.to_s.match?(/\b(iPhone|iPad|iPod|Macintosh)\b/)
  end

  def surround_text(text, prefix = "", suffix = "")
    return "" if text.blank?

    "#{prefix}#{text}#{suffix}"
  end

  def route_boundary_polygon(route, label: nil)
    # sort in Ruby so preloaded points (includes(:points)) are reused.
    points = route.points.sort_by(&:order).filter_map do |point|
      next if point.latitude.blank? || point.longitude.blank?

      { lat: point.latitude.to_f, lng: point.longitude.to_f }
    end

    return [] if points.length <= 3

    [ {
      points: points,
      label: label.presence || "#{route.name} boundary",
      color: ROUTE_AREA_STROKE,
      fillColor: ROUTE_AREA_COLOR
    } ]
  end

  # Route boundary polygons for a multi-route overview, labeled with the zone
  # so an admin can tell which zone each area belongs to.
  def pickups_map_route_polygons(routes)
    Array(routes).flat_map do |route|
      label = [ route.zone&.name.presence || "No Zone", "#{route.name} boundary" ].join(" / ")
      route_boundary_polygon(route, label: label)
    end
  end

  # Single source of truth for pickup status colors on the pickups maps,
  # matching the legend on the pickups overview. Used for both the
  # interactive route map markers and the per-zone overview markers.
  PICKUP_STATUS_COLORS = {
    "pending_pickup" => "#16a34a",
    "picked_up" => "#6b7280",
    "missing" => "#dc2626"
  }.freeze
  ROUTE_AREA_COLOR = "#3b82f6"
  ROUTE_AREA_STROKE = "#2563eb"
  LOCATION_MARKER_COLOR = "#d97706"
  LOCATION_MARKER_STROKE = "#b45309"

  def pickup_status_color(status)
    PICKUP_STATUS_COLORS.fetch(status.to_s, ROUTE_AREA_STROKE)
  end

  def route_area_color
    ROUTE_AREA_COLOR
  end

  def location_marker_color
    LOCATION_MARKER_COLOR
  end

  def pickup_status_swatches
    PICKUP_STATUS_LABELS.map do |status, label|
      { status: status, label: label, color: PICKUP_STATUS_COLORS.fetch(status) }
    end
  end

  # Pending / picked / missing / total counts for a set of routes, built from
  # a grouped { [route_id, status] => count } query.
  def pickup_status_totals(routes, status_counts)
    totals = Reservation::PICKUP_OVERVIEW_STATUSES.index_with(0)
    Array(routes).each do |route|
      totals.each_key do |status|
        totals[status] += status_counts.fetch([ route.id, status ], 0)
      end
    end
    totals["total"] = totals.values.sum
    totals
  end

  def reservation_map_markers(reservations)
    Array(reservations).filter_map do |reservation|
      next if reservation.latitude.blank? || reservation.longitude.blank?

      label = [ reservation.street, reservation.city ].compact_blank.join(", ")
      popup = label.presence || reservation.name
      popup = "#{popup} (#{reservation.status.to_s.titleize})" if popup.present?

      {
        lat: reservation.latitude.to_f,
        lng: reservation.longitude.to_f,
        label: popup,
        popup: popup,
        id: reservation.id
      }
    end
  end

  # Square markers for locations, so they read differently from the circular
  # reservation points at every zoom level.
  def location_map_markers(locations)
    locations = locations.to_a if locations.respond_to?(:to_a)
    Array(locations).filter_map do |location|
      next if location.latitude.blank? || location.longitude.blank?

      popup = [ location.name, location.location_type.to_s.strip.titleize.presence ].compact_blank.join(" · ")

      {
        id: location.id,
        lat: location.latitude.to_f,
        lng: location.longitude.to_f,
        shape: "square",
        color: LOCATION_MARKER_STROKE,
        fillColor: LOCATION_MARKER_COLOR,
        popup: popup
      }
    end
  end

  # Locations inside the given routes' bounded areas, ready for shared/map.
  def location_markers_within(routes)
    location_map_markers(Location.within_routes(routes))
  end

  # Locations that open the shared details dialog instead of a map bubble, so
  # they carry a detail URL and dialog title. The URL is built by the caller so
  # both the driver portal and admin map share the same marker shape.
  def location_detail_markers(locations, detail_url:)
    location_map_markers(locations).each do |marker|
      marker[:detail_url] = detail_url.call(marker[:id])
      marker[:dialog_title] = "Location details"
    end
  end

  # Locations on the driver route map open the shared details dialog.
  def pickups_route_location_markers(route)
    location_detail_markers(Location.within_routes([ route ]), detail_url: ->(id) { pickups_location_path(id) })
  end

  # Map data only: the pickup details dialog fetches the reservation from the
  # server, so markers carry coordinates plus a detail URL and nothing else.
  def pickup_detail_marker(reservation, detail_url:)
    return if reservation.latitude.blank? || reservation.longitude.blank?

    {
      id: reservation.id,
      lat: reservation.latitude.to_f,
      lng: reservation.longitude.to_f,
      status: reservation.status.to_s,
      color: pickup_status_color(reservation.status),
      detail_url: detail_url,
      dialog_title: "Pickup details"
    }
  end

  def pickups_route_map_markers(route, reservations)
    Array(reservations).filter_map do |reservation|
      pickup_detail_marker(reservation, detail_url: pickups_route_reservation_path(route, reservation))
    end
  end

  # Reservation markers for the standalone admin map.
  def admin_pickups_map_markers(reservations)
    Array(reservations).filter_map do |reservation|
      pickup_detail_marker(reservation, detail_url: admin_pickup_reservation_path(reservation))
    end
  end

  # Location markers for the standalone admin map.
  def admin_pickups_location_markers(locations)
    location_detail_markers(locations, detail_url: ->(id) { admin_pickup_location_path(id) })
  end

  # Confirmation message for a driver marking a pickup missing, matching what
  # the reservation callbacks will actually send.
  def pickups_missing_status_confirm(reservation)
    return "Mark this pickup as missing? No notification will be sent because missing-tree notifications are turned off for this reservation." unless reservation.is_missing_tree_notifications_enabled?

    if reservation.mobile.present?
      "Mark this pickup as missing? This will send the resident a missing-tree text message."
    else
      "Mark this pickup as missing? This will send the resident a missing-tree email."
    end
  end

  # Short driver-facing labels for the pickup statuses.
  PICKUP_STATUS_LABELS = {
    "pending_pickup" => "Pending",
    "picked_up" => "Picked",
    "missing" => "Missing"
  }.freeze

  def pickups_status_label(status)
    PICKUP_STATUS_LABELS.fetch(status.to_s, status.to_s.titleize)
  end

  # Status buttons for the pickup popup, in the order drivers read them.
  # The current status renders disabled with a check so a tap cannot
  # accidentally resubmit it.
  def pickup_status_buttons(reservation)
    [
      { value: "pending_pickup", label: "Pending", variant: "secondary", confirm: nil },
      { value: "picked_up", label: "Picked", variant: "primary", confirm: nil },
      { value: "missing", label: "Missing", variant: "danger", confirm: pickups_missing_status_confirm(reservation) }
    ].each { |button| button[:current] = reservation.status.to_s == button[:value] }
  end

  # Anchor identifying a zone panel, so zone titles on the pickups overview
  # can deep-link to the matching zone section on the zones page. Unzoned
  # routes share the "no-zone" anchor.
  def pickups_zone_anchor(zone)
    zone ? dom_id(zone) : "no-zone"
  end

  # Non-interactive markers for the pickups overview maps: colored by status
  # with a popup showing the address and current status.
  def pickups_overview_map_markers(reservations)
    Array(reservations).filter_map do |reservation|
      next if reservation.latitude.blank? || reservation.longitude.blank?

      color = pickup_status_color(reservation.status)
      address = [ reservation.street, reservation.unit.presence, reservation.city, reservation.state ].compact_blank.join(", ")

      {
        id: reservation.id,
        lat: reservation.latitude.to_f,
        lng: reservation.longitude.to_f,
        status: reservation.status.to_s,
        color: color,
        fillColor: color,
        popup: "#{address} (#{reservation.status.to_s.titleize})"
      }
    end
  end
end
