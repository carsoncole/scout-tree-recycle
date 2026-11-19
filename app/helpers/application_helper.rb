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

  def surround_text(text, prefix = "", suffix = "")
    return "" if text.blank?

    "#{prefix}#{text}#{suffix}"
  end

  def route_boundary_polygon(route)
    # sort in Ruby so preloaded points (includes(:points)) are reused.
    points = route.points.sort_by(&:order).filter_map do |point|
      next if point.latitude.blank? || point.longitude.blank?

      { lat: point.latitude.to_f, lng: point.longitude.to_f }
    end

    return [] if points.length <= 3

    [ { points: points, label: "#{route.name} boundary" } ]
  end

  # Single source of truth for pickup status colors on the pickups maps,
  # matching the legend on the pickups overview. Used for both the
  # interactive route map markers and the per-zone overview markers.
  PICKUP_STATUS_COLORS = {
    "pending_pickup" => "#16a34a",
    "picked_up" => "#6b7280",
    "missing" => "#dc2626"
  }.freeze

  def pickup_status_color(status)
    PICKUP_STATUS_COLORS.fetch(status.to_s, "#2563eb")
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

  # Map data only: the route map dialog fetches pickup details from the server,
  # so markers carry coordinates plus a detail URL and nothing else.
  def pickups_route_map_markers(route, reservations)
    Array(reservations).filter_map do |reservation|
      next if reservation.latitude.blank? || reservation.longitude.blank?

      {
        id: reservation.id,
        lat: reservation.latitude.to_f,
        lng: reservation.longitude.to_f,
        status: reservation.status.to_s,
        color: pickup_status_color(reservation.status),
        detail_url: pickups_route_reservation_path(route, reservation)
      }
    end
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
