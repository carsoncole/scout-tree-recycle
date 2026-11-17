module AdminHelper
  ADMIN_NAV_CLASSES = "admin-nav-link text-ink-soft hover:text-ink dark:text-ink-soft-dark dark:hover:text-ink-dark".freeze
  ADMIN_NAV_ACTIVE_CLASSES = "is-active bg-sage-soft text-sage-deep dark:bg-sage-soft-dark dark:text-sage-deep-dark".freeze

  ADMIN_BADGE_CLASSES = {
    "neutral" => "bg-stone text-ink-soft dark:bg-stone-dark dark:text-ink-soft-dark",
    "positive" => "bg-positive-bg text-positive dark:bg-positive-bg-dark dark:text-positive-dark",
    "info" => "bg-info-bg text-info dark:bg-info-bg-dark dark:text-info-dark",
    "warning" => "bg-warning-badge text-warning-badge-text dark:bg-warning-badge-dark dark:text-warning-badge-text-dark",
    "danger" => "bg-danger-bg-strong text-danger dark:bg-danger-bg-strong-dark dark:text-danger-dark"
  }.freeze

  def admin_nav_class(active)
    [ ADMIN_NAV_CLASSES, (ADMIN_NAV_ACTIVE_CLASSES if active) ].compact.join(" ")
  end

  ADMIN_INPUT_CLASSES = "border border-line-strong bg-surface text-ink placeholder-muted hover:border-ink-soft focus:border-sage focus:bg-[#fffdf8] disabled:bg-stone disabled:text-muted dark:border-line-strong-dark dark:bg-stone-dark dark:text-ink-dark dark:placeholder-muted-dark dark:hover:border-ink-soft-dark dark:focus:border-sage-dark dark:focus:bg-input-focus-dark dark:disabled:bg-stone-dark dark:disabled:text-muted-dark".freeze
  ADMIN_INPUT_ERROR_CLASSES = "border border-danger-border bg-surface text-ink placeholder-muted focus:border-danger-border focus:bg-[#fffdf8] disabled:bg-stone disabled:text-muted dark:border-danger-border-dark dark:bg-stone-dark dark:text-ink-dark dark:placeholder-muted-dark dark:focus:border-danger-border-dark dark:focus:bg-input-focus-dark dark:disabled:bg-stone-dark dark:disabled:text-muted-dark".freeze
  ADMIN_SELECT_CLASSES = "border border-line-strong bg-surface text-ink hover:border-ink-soft focus:border-sage disabled:bg-stone disabled:text-muted dark:border-line-strong-dark dark:bg-stone-dark dark:text-ink-dark dark:hover:border-ink-soft-dark dark:focus:border-sage-dark dark:disabled:bg-stone-dark dark:disabled:text-muted-dark".freeze
  ADMIN_SELECT_ERROR_CLASSES = "border border-danger-border bg-surface text-ink focus:border-danger-border disabled:bg-stone disabled:text-muted dark:border-danger-border-dark dark:bg-stone-dark dark:text-ink-dark dark:focus:border-danger-border-dark dark:disabled:bg-stone-dark dark:disabled:text-muted-dark".freeze

  def admin_input_class(error: false)
    "admin-input #{error ? "admin-input--error #{ADMIN_INPUT_ERROR_CLASSES}" : ADMIN_INPUT_CLASSES}"
  end

  def admin_select_class(error: false)
    "admin-select #{error ? "admin-select--error #{ADMIN_SELECT_ERROR_CLASSES}" : ADMIN_SELECT_CLASSES}"
  end

  def admin_badge_class(variant)
    variant = variant.to_s
    colors = ADMIN_BADGE_CLASSES.fetch(variant, ADMIN_BADGE_CLASSES["neutral"])
    "admin-badge admin-badge--#{variant} #{colors}"
  end

  def admin_reservation_status_badge(status)
    variant = {
      "pending_pickup" => "positive",
      "picked_up" => "info",
      "cancelled" => "danger",
      "missing" => "warning",
      "imported" => "info"
    }.fetch(status.to_s, "neutral")

    admin_badge_class(variant)
  end

  def admin_log_severity_badge(severity)
    variant = {
      "error" => "danger",
      "warning" => "warning",
      "info" => "info"
    }.fetch(severity.to_s, "neutral")

    admin_badge_class(variant)
  end

  def admin_donation_status_badge(status)
    admin_badge_class(status.to_s == "completed" ? "positive" : "warning")
  end

  def admin_handled_badge(handled)
    admin_badge_class(handled ? "positive" : "danger")
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

  def admin_external_link_icon
    tag.svg(
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": 1.8,
      class: "size-3 shrink-0",
      aria: { hidden: true }
    ) do
      tag.path(
        d: "M7 17 17 7M9 7h8v8",
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

  def admin_marketing_send_confirm(name, batch_size)
    if batch_size.zero?
      "Send #{name}? No contacts are currently eligible."
    else
      "Send #{name} to #{pluralize(batch_size, "contact")}? Contacts who already received it will be skipped. This cannot be undone."
    end
  end

  def admin_resend_email_confirm(label, sent_at, email)
    if sent_at.present?
      "This #{label.downcase} was already sent to #{email} on #{sent_at.strftime("%B %-d, %Y at %-l:%M %p")}. Are you sure you want to send it again?"
    else
      "Send the #{label.downcase} to #{email}?"
    end
  end
end
