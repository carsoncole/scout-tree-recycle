module AdminHelper
  # Top-nav groups. Each entry is [label, [controller names]].
  ADMIN_NAV_GROUPS = {
    "Operations" => %w[reservations pickups donations analytics sms received_emails outbound_emails replies marketing marketing_email_templates marketing_images reservation_email_templates contacts],
    "System" => %w[settings configuration drivers routes zones locations users thanks logs data operations]
  }.freeze

  ADMIN_NAV_CLASSES = "admin-nav-link text-ink-soft hover:text-ink hover:bg-stone dark:text-ink-soft-dark dark:hover:text-ink-dark dark:hover:bg-stone-dark".freeze
  ADMIN_NAV_ACTIVE_CLASSES = "is-active bg-sage-soft text-sage-deep hover:bg-sage-soft dark:bg-sage-soft-dark dark:text-sage-deep-dark".freeze

  ADMIN_SETTINGS_NAV_CLASSES = "admin-settings-nav-link bg-cool text-ink-soft hover:bg-sage-soft hover:text-ink dark:bg-cool-dark dark:text-ink-soft-dark dark:hover:bg-sage-soft-dark dark:hover:text-ink-dark".freeze
  ADMIN_SETTINGS_NAV_ACTIVE_CLASSES = "is-active bg-sage-soft text-sage-deep dark:bg-sage-soft-dark dark:text-sage-deep-dark".freeze

  ADMIN_BADGE_CLASSES = {
    "neutral" => "bg-stone text-ink-soft dark:bg-stone-dark dark:text-ink-soft-dark",
    "positive" => "bg-positive-bg text-positive dark:bg-positive-bg-dark dark:text-positive-dark",
    "info" => "bg-info-bg text-info dark:bg-info-bg-dark dark:text-info-dark",
    "warning" => "bg-warning-badge text-warning-badge-text dark:bg-warning-badge-dark dark:text-warning-badge-text-dark",
    "danger" => "bg-danger-bg-strong text-danger dark:bg-danger-bg-strong-dark dark:text-danger-dark"
  }.freeze

  CONFIGURATION_STATUS_BADGES = {
    "missing" => "danger",
    "configured" => "positive",
    "default" => "info",
    "not_set" => "neutral",
    "not_needed" => "neutral"
  }.freeze

  # What each signed-in role can do. Matches the controller checks.
  # :user and :admin are true when that role is allowed.
  ADMIN_ROLE_PRIVILEGES = [
    { area: "Operations", label: "Reservations, pickups, donations, analytics, SMS, and mail", user: true, admin: true },
    { area: "Operations", label: "Marketing, templates, images, and contacts", user: true, admin: true },
    { area: "Operations", label: "Delete all contacts", user: false, admin: true },
    { area: "Operations", label: "Thank-you message and supporter thanks", user: true, admin: true },
    { area: "Routing", label: "Routes, zones, drivers, and route points", user: true, admin: true },
    { area: "Routing", label: "Locations — staging points, meeting places, and other map locations", user: true, admin: true },
    { area: "System", label: "Logs, including delete and delete all", user: true, admin: true },
    { area: "System", label: "Configuration report", user: true, admin: true },
    { area: "System", label: "Jobs dashboard, including retry, discard, and queue pause", user: true, admin: true },
    { area: "Data", label: "View the data page and database settings", user: true, admin: true },
    { area: "Data", label: "Download or email backups, restore reservations, contacts or settings, and manage data", user: false, admin: true },
    { area: "Data", label: "Delete all reservations or all contacts", user: false, admin: true },
    { area: "Data", label: "Reset all data to default (danger zone)", user: false, admin: true },
    { area: "Users", label: "View the user list and these privileges", user: true, admin: true },
    { area: "Users", label: "Create, edit, and delete users", user: false, admin: true },
    { area: "Settings", label: "View settings and the close-event page", user: true, admin: true },
    { area: "Settings", label: "Update settings, toggles, test email, retention, and close the event", user: false, admin: true },
    { area: "Account", label: "Edit own email and password", user: true, admin: true }
  ].freeze

  def admin_role_privileges
    ADMIN_ROLE_PRIVILEGES
  end

  def admin_privilege_mark(allowed)
    if allowed
      tag.span(class: "text-lg font-semibold leading-none text-positive dark:text-positive-dark") do
        safe_join([
          tag.span("✓", aria: { hidden: true }),
          tag.span("Allowed", class: "sr-only")
        ])
      end
    else
      tag.span(class: "text-lg leading-none text-muted dark:text-muted-dark") do
        safe_join([
          tag.span("—", aria: { hidden: true }),
          tag.span("Not allowed", class: "sr-only")
        ])
      end
    end
  end

  def admin_nav_class(active)
    [ ADMIN_NAV_CLASSES, (ADMIN_NAV_ACTIVE_CLASSES if active) ].compact.join(" ")
  end

  def admin_nav_group_label
    ADMIN_NAV_GROUPS.find { |_label, controllers| controllers.include?(controller_name) }&.first
  end

  def admin_settings_nav_items
    section_items = Setting::SECTIONS.reject { |key, _| key == "system" }.map do |key, metadata|
      {
        key: key,
        label: metadata[:label],
        description: metadata[:description],
        path: admin_settings_section_path(key)
      }
    end

    section_items << {
      key: "users",
      label: "Users",
      description: "Manage system users and their permissions.",
      path: admin_users_path
    }

    system = Setting::SECTIONS.fetch("system")
    section_items << {
      key: "system",
      label: system[:label],
      description: system[:description],
      path: admin_settings_section_path("system")
    }
  end

  def admin_settings_active_key
    case controller_name
    when "settings"
      @section.presence || "overview"
    when "drivers", "zones", "routes", "locations"
      "pickups"
    when "thanks"
      "site_content"
    when "operations", "logs"
      "system"
    else
      controller_name
    end
  end

  def admin_settings_nav_class(key)
    classes = [ ADMIN_SETTINGS_NAV_CLASSES ]
    classes << ADMIN_SETTINGS_NAV_ACTIVE_CLASSES if admin_settings_active_key == key
    classes.join(" ")
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

  def admin_textarea_class(error: false)
    "admin-textarea #{admin_input_class(error: error)}"
  end

  ADMIN_BUTTON_CLASSES = {
    "primary" => "bg-sage text-surface hover:bg-sage-deep dark:bg-sage-dark dark:text-page-dark dark:hover:bg-sage-deep-dark",
    "secondary" => "border border-line-strong bg-surface text-ink hover:bg-stone dark:border-line-strong-dark dark:bg-surface-dark dark:text-ink-dark dark:hover:bg-stone-dark",
    "danger" => "bg-danger text-surface hover:bg-[#743730] dark:bg-danger-dark dark:text-page-dark dark:hover:bg-danger-border-dark",
    "quiet" => "text-ink-soft hover:text-ink dark:text-ink-soft-dark dark:hover:text-ink-dark"
  }.freeze

  # Shape modifiers ("small", "full") append the matching admin-button--* class.
  def admin_button_class(variant: "primary", size: nil, full: false)
    variant = variant.to_s
    classes = [ "admin-button" ]
    classes << "admin-button--#{variant}" unless variant == "primary"
    classes << ADMIN_BUTTON_CLASSES.fetch(variant, ADMIN_BUTTON_CLASSES["primary"])
    classes << "admin-button--small" if size == "small"
    classes << "admin-button--full" if full
    classes.join(" ")
  end

  ADMIN_LINK_CLASSES = "text-sage-deep hover:text-ink dark:text-sage-deep-dark dark:hover:text-ink-dark".freeze
  ADMIN_LINK_DANGER_CLASSES = "text-danger hover:text-[#743730] dark:text-danger-dark dark:hover:text-danger-border-dark".freeze
  ADMIN_LINK_MUTED_CLASSES = "text-ink-soft dark:text-ink-soft-dark".freeze

  def admin_link_class(variant: "default")
    case variant.to_s
    when "danger"
      "admin-link admin-link--danger #{ADMIN_LINK_DANGER_CLASSES}"
    when "muted"
      "admin-link admin-link--muted #{ADMIN_LINK_MUTED_CLASSES}"
    else
      "admin-link #{ADMIN_LINK_CLASSES}"
    end
  end

  ADMIN_FILTER_CLASSES = "text-ink-soft hover:text-ink dark:text-ink-soft-dark dark:hover:text-ink-dark".freeze
  ADMIN_FILTER_ACTIVE_CLASSES = "is-active bg-sage text-surface dark:bg-sage-dark dark:text-page-dark".freeze

  def admin_filter_class(active)
    "admin-filter #{active ? ADMIN_FILTER_ACTIVE_CLASSES : ADMIN_FILTER_CLASSES}"
  end

  ADMIN_NOTICE_CLASSES = {
    "info" => "border border-line border-l-[3px] border-l-sage bg-sage-soft text-ink dark:border-line-dark dark:border-l-sage-dark dark:bg-sage-soft-dark dark:text-ink-dark",
    "alert" => "border border-line border-l-[3px] border-l-ink-soft bg-stone text-ink dark:border-line-dark dark:border-l-ink-soft-dark dark:bg-stone-dark dark:text-ink-dark",
    "warning" => "border border-line border-l-[3px] border-l-warning bg-warning-bg text-ink dark:border-line-dark dark:border-l-warning-dark dark:bg-warning-bg-dark dark:text-ink-dark",
    "danger" => "border border-line border-l-[3px] border-l-danger-border bg-danger-bg text-ink dark:border-line-dark dark:border-l-danger-border-dark dark:bg-danger-bg-dark dark:text-ink-dark"
  }.freeze

  def admin_notice_class(variant = "info", spaced: false)
    variant = variant.to_s
    classes = [ "admin-notice" ]
    classes << "admin-notice--#{variant}" unless variant == "info"
    classes << "admin-notice--spaced" if spaced
    classes << ADMIN_NOTICE_CLASSES.fetch(variant, ADMIN_NOTICE_CLASSES["info"])
    classes.join(" ")
  end

  ADMIN_TABLE_HEADER_CELL_CLASSES = "border-b border-line bg-stone text-ink-soft dark:border-line-dark dark:bg-stone-dark dark:text-ink-soft-dark".freeze
  ADMIN_TABLE_BODY_CELL_CLASSES = "border-b border-line text-ink dark:border-line-dark dark:text-ink-dark".freeze

  def admin_th_class
    ADMIN_TABLE_HEADER_CELL_CLASSES
  end

  def admin_td_class
    ADMIN_TABLE_BODY_CELL_CLASSES
  end

  ADMIN_PAGINATION_LINK_CLASSES = "border border-line text-ink-soft hover:bg-stone hover:text-ink dark:border-line-dark dark:text-ink-soft-dark dark:hover:bg-stone-dark dark:hover:text-ink-dark".freeze
  ADMIN_PAGINATION_CURRENT_CLASSES = "is-current border-sage bg-sage text-surface dark:border-sage-dark dark:bg-sage-dark dark:text-page-dark".freeze

  def admin_pagination_link_class(current: false)
    "admin-pagination-link #{current ? ADMIN_PAGINATION_CURRENT_CLASSES : ADMIN_PAGINATION_LINK_CLASSES}"
  end

  def admin_badge_class(variant)
    variant = variant.to_s
    colors = ADMIN_BADGE_CLASSES.fetch(variant, ADMIN_BADGE_CLASSES["neutral"])
    "admin-badge admin-badge--#{variant} #{colors}"
  end

  # Readable status badge for a ConfigurationOverview entry.
  def admin_configuration_status_badge(status)
    variant = CONFIGURATION_STATUS_BADGES.fetch(status.to_s, "neutral")
    tag.span(status.to_s.humanize, class: admin_badge_class(variant))
  end

  # Value column for a ConfigurationOverview entry. Secrets are always masked;
  # blanks render as an em dash; long text is truncated.
  def admin_configuration_value(entry)
    value = entry.value
    return "On" if value == true
    return "Off" if value == false
    return tag.span("—", class: "text-muted dark:text-muted-dark") if value.nil? || value.to_s.strip.empty?
    return tag.span("●●●●●●●●", class: "text-ink-soft dark:text-ink-soft-dark", title: "Hidden for safety") if entry.secret

    case value
    when Time, DateTime
      value.in_time_zone.strftime("%b %-d, %-l:%M %p")
    when Integer
      entry.attribute == :suggested_donation ? "$#{value}" : value.to_s
    else
      truncate(value.to_s, length: 80)
    end
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

  # Compact one-line JSON for a log's context so index table cells stay
  # scannable. Full pretty-printed context lives on the log's show page.
  def admin_log_context_json(log)
    return if log.context.blank?

    log.context.is_a?(String) ? log.context : JSON.generate(log.context)
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

  def admin_mail_icon
    tag.svg(
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": 1.6,
      class: "admin-icon",
      aria: { hidden: true }
    ) do
      tag.path(
        d: "M6 12 3.269 3.125A59.769 59.769 0 0 1 21.485 12 59.768 59.768 0 0 1 3.27 20.875L5.999 12Zm0 0h7.5",
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

  # Prefills the test-email recipient with the signed-in admin's address,
  # falling back to the configured contact address.
  def admin_test_email_recipient
    Current.user&.email.presence || Setting.instance&.contact_email
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
