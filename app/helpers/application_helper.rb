module ApplicationHelper
  def setting
    @setting ||= Setting.instance
  end

  def surround_text(text, prefix = "", suffix = "")
    return "" if text.blank?

    "#{prefix}#{text}#{suffix}"
  end

  def route_boundary_polygon(route)
    points = route.points.order(:order).filter_map do |point|
      next if point.latitude.blank? || point.longitude.blank?

      { lat: point.latitude.to_f, lng: point.longitude.to_f }
    end

    return [] if points.length <= 3

    [ { points: points, label: "#{route.name} boundary" } ]
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

  def pickups_route_map_markers(route, reservations)
    Array(reservations).filter_map do |reservation|
      next if reservation.latitude.blank? || reservation.longitude.blank?

      address = [ reservation.street, reservation.unit.presence, reservation.city, reservation.state ].compact_blank.join(", ")
      color = case reservation.status.to_s
      when "pending_pickup" then "#16a34a"
      when "missing" then "#dc2626"
      when "picked_up" then "#6b7280"
      else "#2563eb"
      end

      {
        id: reservation.id,
        lat: reservation.latitude.to_f,
        lng: reservation.longitude.to_f,
        status: reservation.status.to_s,
        status_label: reservation.status.to_s.titleize,
        address: address,
        pickup_notes: reservation.pickup_notes.to_s,
        color: color,
        update_url: pickups_route_reservation_path(route, reservation)
      }
    end
  end
end
