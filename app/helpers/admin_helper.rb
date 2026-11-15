module AdminHelper
  def admin_nav_class(active)
    [ "admin-nav-link", ("is-active" if active) ].compact.join(" ")
  end

  def admin_reservation_status_badge(status)
    variant = {
      "pending_pickup" => "positive",
      "picked_up" => "info",
      "cancelled" => "danger",
      "missing" => "warning",
      "imported" => "info"
    }.fetch(status.to_s, "neutral")

    "admin-badge admin-badge--#{variant}"
  end

  def admin_log_severity_badge(severity)
    variant = {
      "error" => "danger",
      "warning" => "warning",
      "info" => "info"
    }.fetch(severity.to_s, "neutral")

    "admin-badge admin-badge--#{variant}"
  end

  def admin_donation_status_badge(status)
    "admin-badge admin-badge--#{status.to_s == "completed" ? "positive" : "warning"}"
  end

  def admin_handled_badge(handled)
    "admin-badge admin-badge--#{handled ? "positive" : "danger"}"
  end

  def admin_trash_icon
    tag.svg(
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": 1.6,
      class: "admin-icon",
      aria: { hidden: true }
    ) do
      tag.path(
        d: "M4 7h16M10 4h4M6 7l1 13h10l1-13M10 11v6M14 11v6",
        "stroke-linecap": "round",
        "stroke-linejoin": "round"
      )
    end
  end

  # Shows the year only for sends from previous years to keep table cells compact.
  def admin_marketing_sent_at(time)
    time = time.in_time_zone
    format = time.year == Time.current.year ? "%b %-d, %-l:%M %p" : "%b %-d, %Y %-l:%M %p"
    time.strftime(format)
  end
end
