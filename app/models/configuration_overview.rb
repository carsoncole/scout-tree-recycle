# Read-only status report for every configurable setting, grouped by the
# settings sections. Each entry reports the current value and whether it is
# missing, configured, or still using its built-in default. Secret values are
# marked so views can mask them.
class ConfigurationOverview
  Entry = Struct.new(:attribute, :label, :note, :secret, :value, :status, keyword_init: true)
  Group = Struct.new(:key, :label, :description, :toggle, :entries, keyword_init: true)

  # Catalog of reportable settings per section. `required` entries must always
  # be set. `conditional_on` entries are only required while that feature
  # toggle is enabled. Everything else is compared against its built-in
  # default (an unset value means the default is in effect).
  CATALOG = {
    "event" => {
      toggle: :is_reservations_open,
      entries: [
        { attribute: :event_pickup_start, label: "Event Pickup Date/Time", required: true,
          note: "Opens the pickup window; shown on the reservation form and in emails." },
        { attribute: :event_pickup_end, label: "Event Pickup End Date/Time", required: true,
          note: "Closes the pickup window." },
        { attribute: :event_sign_up_deadline, label: "Sign Up Deadline", required: true,
          note: "New reservations close at this date and time." },
        { attribute: :default_city, label: "Default City", required: true,
          note: "City prefilled on new reservations." },
        { attribute: :default_state, label: "Default State", required: true,
          note: "State prefilled on new reservations." },
        { attribute: :is_reservations_open, label: "Reservations",
          note: "Master switch for accepting new reservations." },
        { attribute: :reservations_closed_message, label: "Reservations Closed Message",
          note: "Shown instead of the form while reservations are closed." },
        { attribute: :suggested_donation, label: "Suggested Donation",
          note: "Amount suggested on the donation page." },
        { attribute: :contact_name, label: "Contact Name",
          note: "Shown on the About page." },
        { attribute: :contact_email, label: "Contact Email",
          note: "Shown on the About page; also the fallback From address." },
        { attribute: :contact_phone, label: "Contact Phone",
          note: "Shown on the About page." },
        { attribute: :contact_sms, label: "Contact SMS",
          note: "Shown on the About page." }
      ]
    },
    "organization" => {
      entries: [
        { attribute: :organization_name, label: "Organization Name", required: true,
          note: "Used in the site header, footer, emails, and page titles." },
        { attribute: :organization_url, label: "Organization URL",
          note: "Optional link in the footer." },
        { attribute: :thank_you_message, label: "Thank You Message",
          note: "Shown on the Thank You page after a reservation." }
      ]
    },
    "site_details" => {
      entries: [
        { attribute: :site_url, label: "Site URL", required: true,
          note: "Host used for links in emails and webhooks." },
        { attribute: :time_zone, label: "Time Zone",
          note: "Applied to emails, jobs, and scheduled sends." },
        { attribute: :default_country, label: "Default Country",
          note: "Country prefilled on new reservations." },
        { attribute: :phone_default_country, label: "Default Phone Country",
          note: "Used when parsing phone numbers for SMS." }
      ]
    },
    "site_content" => {
      entries: [
        { attribute: :home_page_header, label: "Header/Tab Title",
          note: "Browser tab and page title." },
        { attribute: :home_page_image, label: "Home Page Image",
          note: "Hero image on the home page." },
        { attribute: :about_event_description, label: "About Description",
          note: "About page description." },
        { attribute: :on_day_of_pickup_instructions, label: "On Day of Pickup Instructions",
          note: "Shown to customers and drivers on pickup day." },
        { attribute: :donations_page_content, label: "Donations Initial Content",
          note: "Copy on the donations page." },
        { attribute: :donations_page_how_to_donate, label: "How to Donate",
          note: "Cash or check instructions on the donations page." },
        { attribute: :donations_new_page_content, label: "New Donations Page Content",
          note: "Copy on the donation checkout page." },
        { attribute: :donations_success_page_content, label: "Donation Success Content",
          note: "Copy shown after a donation." }
      ]
    },
    "pickups" => {
      toggle: :is_pickups_site_enabled,
      entries: [
        { attribute: :is_pickups_site_enabled, label: "Pickups Portal",
          note: "Master switch for the driver portal." },
        { attribute: :driver_secret_key, label: "Password", conditional_on: :is_pickups_site_enabled, secret: true,
          note: "Password drivers enter to access the portal." }
      ]
    },
    "sms" => {
      toggle: :is_sms_enabled,
      entries: [
        { attribute: :is_sms_enabled, label: "SMS",
          note: "Master switch for outbound SMS." },
        { attribute: :twilio_account_sid, label: "Account SID", conditional_on: :is_sms_enabled,
          note: "Twilio console credential." },
        { attribute: :twilio_auth_token, label: "Auth Token", conditional_on: :is_sms_enabled, secret: true,
          note: "Twilio console credential." },
        { attribute: :twilio_from_number, label: "From Number", conditional_on: :is_sms_enabled,
          note: "Number messages are sent from." },
        { attribute: :sms_quick_responses, label: "Quick Responses",
          note: "One-click replies in SMS conversations." },
        { attribute: :missing_tree_sms_message, label: "Missing Tree First Message",
          note: "Sent when a reservation is first marked missing." },
        { attribute: :missing_tree_sms_follow_up_message, label: "Missing Tree Follow-up Message",
          note: "Sent when a reservation is marked missing again." }
      ]
    },
    "email" => {
      toggle: :is_emailing_enabled,
      entries: [
        { attribute: :is_emailing_enabled, label: "Email",
          note: "Master switch for all outbound email." },
        { attribute: :email_from_address, label: "From Address", conditional_on: :is_emailing_enabled,
          note: "Sending address for all outbound email." },
        { attribute: :smtp_address, label: "SMTP Address", conditional_on: :is_emailing_enabled,
          note: "SMTP server host." },
        { attribute: :smtp_port, label: "Port", conditional_on: :is_emailing_enabled,
          note: "SMTP server port." },
        { attribute: :smtp_user_name, label: "Username",
          note: "SMTP username, if the server requires one." },
        { attribute: :smtp_password, label: "Password", secret: true,
          note: "SMTP password, if the server requires one." },
        { attribute: :smtp_authentication, label: "Authentication",
          note: "SMTP authentication method." },
        { attribute: :smtp_encryption, label: "Encryption",
          note: "SMTP connection security." },
        { attribute: :email_batch_quantity, label: "Email Batch Quantity",
          note: "Caps marketing sends per batch." },
        { attribute: :marketing_email_cooldown_days, label: "Days Between Marketing Emails",
          note: "Cooldown between marketing sends." }
      ]
    },
    "donations" => {
      toggle: :is_donations_enabled,
      entries: [
        { attribute: :is_donations_enabled, label: "Online Donations",
          note: "Master switch for Stripe checkout on the donation page." },
        { attribute: :stripe_secret_key, label: "Stripe Secret Key", conditional_on: :is_donations_enabled, secret: true,
          note: "Applied per request to the Stripe API." },
        { attribute: :stripe_price_id, label: "Stripe Price ID", conditional_on: :is_donations_enabled,
          note: "The price donors are charged." }
      ]
    },
    "location_services" => {
      toggle: :is_routing_enabled,
      entries: [
        { attribute: :is_routing_enabled, label: "Automatic Routing",
          note: "Master switch for geocoding and route assignment." },
        { attribute: :aws_access_key_id, label: "Access Key ID", conditional_on: :is_routing_enabled,
          note: "Amazon Location Service credential." },
        { attribute: :aws_secret_access_key, label: "Secret Access Key", conditional_on: :is_routing_enabled, secret: true,
          note: "Amazon Location Service credential." },
        { attribute: :aws_region, label: "Region", conditional_on: :is_routing_enabled,
          note: "AWS region of the place index." },
        { attribute: :aws_location_index_name, label: "Place Index Name", conditional_on: :is_routing_enabled,
          note: "The Amazon Location Service place index." }
      ]
    },
    "operations" => {
      toggle: :is_reservations_export_schedule_enabled,
      entries: [
        { attribute: :contact_retention_months, label: "Retention (Months)",
          note: "Contacts older than this are removed by end-of-season cleanup." },
        { attribute: :is_reservations_export_schedule_enabled, label: "Daily Reservations Export",
          note: "Scheduled CSV email; managed on the Data page." },
        { attribute: :reservations_export_email, label: "Export Recipient", conditional_on: :is_reservations_export_schedule_enabled,
          note: "Receives the daily reservations CSV; managed on the Data page." },
        { attribute: :reservations_export_time, label: "Export Send Time", conditional_on: :is_reservations_export_schedule_enabled,
          note: "Send time for the daily export; managed on the Data page." }
      ]
    },
    "system" => {
      toggle: :is_log_notifications_enabled,
      entries: [
        { attribute: :is_log_notifications_enabled, label: "Error Notifications",
          note: "Emails admins when errors are logged." }
      ]
    }
  }.freeze

  def initialize(setting)
    @setting = setting
    @defaults = Setting.new
  end

  def groups
    CATALOG.map do |key, spec|
      metadata = Setting::SECTIONS.fetch(key)

      Group.new(
        key: key,
        label: metadata[:label],
        description: metadata[:description],
        toggle: spec[:toggle],
        entries: spec[:entries].map { |entry_spec| build_entry(entry_spec) }
      )
    end
  end

  def missing_count
    groups.sum { |group| group.entries.count { |entry| entry.status == :missing } }
  end

  private

  def build_entry(spec)
    attribute = spec.fetch(:attribute)
    value = @setting.public_send(attribute)

    Entry.new(
      attribute: attribute,
      label: spec.fetch(:label),
      note: spec[:note],
      secret: spec.fetch(:secret, false),
      value: value,
      status: status_for(spec, value)
    )
  end

  def status_for(spec, value)
    if spec[:required]
      return value.blank? ? :missing : :configured
    end

    if (toggle = spec[:conditional_on])
      return :missing if value.blank? && @setting.public_send(toggle)
      return :not_needed if value.blank?
    end

    default = default_for(spec.fetch(:attribute))

    if default.nil?
      value.blank? ? :not_set : :configured
    elsif value.blank?
      :default
    else
      value == default ? :default : :configured
    end
  end

  def default_for(attribute)
    return derived_home_page_header if attribute == :home_page_header

    @defaults.public_send(attribute)
  end

  # home_page_header is derived from the organization name when blank, so a
  # header matching the derived value still reports as the default.
  def derived_home_page_header
    return nil if @setting.organization_name.blank?

    "#{@setting.organization_name.strip} Tree Recycle"
  end
end
