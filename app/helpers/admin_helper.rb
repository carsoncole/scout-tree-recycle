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
end
