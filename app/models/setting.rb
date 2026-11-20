class Setting < ApplicationRecord
  AVAILABLE_TIME_ZONES = [
    "Eastern Time (US & Canada)",
    "Central Time (US & Canada)",
    "Mountain Time (US & Canada)",
    "Pacific Time (US & Canada)",
    "Alaska",
    "Hawaii",
    "UTC"
  ].freeze

  DEFAULT_TIME_ZONE = "Pacific Time (US & Canada)"
  DEFAULT_COUNTRY = "United States"
  DEFAULT_PHONE_COUNTRY = "US"
  DEFAULT_SUGGESTED_DONATION = 25
  DEFAULT_EMAIL_BATCH_QUANTITY = 100
  DEFAULT_MARKETING_COOLDOWN_DAYS = 7
  DEFAULT_RETENTION_MONTHS = 24
  DEFAULT_ABOUT_EVENT_DESCRIPTION = "This is a community event where we collect trees and recycle them into mulch. It's an important fundraiser for our organization, and the proceeds go towards supporting us."
  DEFAULT_PICKUP_INSTRUCTIONS = "To prepare your tree for pick-up, remove all decorations and tinsel from your tree. Prior to pickup, place your tree in a visible location at the curb or where you indicated to us in your reservation. Your tree will be collected and recycled into mulch. We cannot take wreaths, flocked trees, or artificial trees. If we can not find your tree, we will try contacting you by SMS or phone call to make arrangements to attempt another pick-up."
  DEFAULT_THANK_YOU_MESSAGE = "We want to say thank you to our community and to the supporters who make this fundraiser possible. Their generosity supports our Scouting program and the environment."
  DEFAULT_RESERVATIONS_CLOSED_MESSAGE = "Stay tuned for when we open reservations again."
  DEFAULT_DONATIONS_PAGE_CONTENT = "Thank you for your interest in supporting our organization. Your generosity helps us continue our work of environmental stewardship and community service."
  DEFAULT_DONATIONS_PAGE_HOW_TO_DONATE = "If you would like to make a donation, you can leave cash or a check in a ziplock bag with your tree on the day of pickup. Our volunteers will collect it along with your tree.\n\nYour support makes a real difference in our community and helps us continue this annual fundraiser."
  DEFAULT_DONATIONS_NEW_PAGE_CONTENT = "Our tree pickup service is free, but it's also our biggest fundraiser of the year. Every donation goes straight to our organization and helps our members take part in:\n\n- Summer camps and outdoor adventures\n- Leadership and team-building activities\n- Community service projects"
  DEFAULT_DONATIONS_SUCCESS_PAGE_CONTENT = "Thanks to you, our organization can keep adventuring, leading, and giving back to the community. We'll put your donation to good use."
  DEFAULT_HOME_PAGE_IMAGE = "tree-4c-bc.png"
  DEFAULT_MAILER_LOGO = "fleur-de-lis-2024-logo-4c-bc-small.png"
  DEFAULT_RESERVATIONS_EXPORT_TIME = "06:00"
  RESERVATIONS_EXPORT_TIME_FORMAT = /\A([01]\d|2[0-3]):[0-5]\d\z/

  # Half-hour send times offered for the daily reservations CSV export.
  RESERVATIONS_EXPORT_TIMES = (0..47).map { |slot| format("%02d:%02d", slot / 2, (slot % 2) * 30) }.freeze

  SECTIONS = {
    "event" => {
      label: "The Event",
      description: "Public copy, pickup windows, reservation availability, and contact information."
    },
    "organization" => {
      label: "Organization",
      description: "Organization name and website."
    },
    "site_details" => {
      label: "Site Details",
      description: "Site address, time zone, and default country used throughout the app."
    },
    "site_content" => {
      label: "Site Content",
      description: "Headline, home page image, and supporting copy shown on the public site."
    },
    "pickups" => {
      label: "Pickups Portal",
      description: "Enable the driver portal and manage driver access."
    },
    "sms" => {
      label: "SMS",
      description: "Send and receive text messages through Twilio."
    },
    "email" => {
      label: "Email",
      description: "Send notifications and marketing messages through SMTP."
    },
    "donations" => {
      label: "Donations",
      description: "Accept online donations through Stripe."
    },
    "location_services" => {
      label: "Location Services",
      description: "Geocode reservation and route addresses with Amazon Location Service."
    },
    "system" => {
      label: "System",
      description: "Take the public site down for maintenance, show the pickup notice, review system errors, close the current event, and delete or reset data."
    }
  }.freeze

  REQUIRED_SETTINGS = [
    { attribute: :organization_name, label: "Organization Name", section: "organization" },
    { attribute: :site_url, label: "Site URL", section: "site_details" },
    { attribute: :default_city, label: "Default City", section: "event" },
    { attribute: :default_state, label: "Default State", section: "event" },
    { attribute: :event_pickup_start, label: "Event Pickup Start", section: "event" },
    { attribute: :event_pickup_end, label: "Event Pickup End", section: "event" },
    { attribute: :event_sign_up_deadline, label: "Sign Up Deadline", section: "event" }
  ].freeze

  REQUIRED_EMAIL_SETTINGS = [
    { attribute: :email_from_address, label: "Email From Address", section: "email" },
    { attribute: :smtp_address, label: "SMTP Address", section: "email" },
    { attribute: :smtp_port, label: "SMTP Port", section: "email" }
  ].freeze

  SENSITIVE_SETTING_ATTRIBUTES = %w[
    twilio_auth_token
    smtp_password
    stripe_secret_key
    aws_secret_access_key
    driver_secret_key
  ].freeze

  attribute :on_day_of_pickup_instructions, :string, default: DEFAULT_PICKUP_INSTRUCTIONS
  attribute :about_event_description, :string, default: DEFAULT_ABOUT_EVENT_DESCRIPTION
  attribute :reservations_closed_message, :string, default: DEFAULT_RESERVATIONS_CLOSED_MESSAGE
  attribute :donations_page_content, :string, default: DEFAULT_DONATIONS_PAGE_CONTENT
  attribute :donations_page_how_to_donate, :string, default: DEFAULT_DONATIONS_PAGE_HOW_TO_DONATE
  attribute :donations_new_page_content, :string, default: DEFAULT_DONATIONS_NEW_PAGE_CONTENT
  attribute :donations_success_page_content, :string, default: DEFAULT_DONATIONS_SUCCESS_PAGE_CONTENT
  attribute :time_zone, :string, default: DEFAULT_TIME_ZONE
  attribute :suggested_donation, :integer, default: DEFAULT_SUGGESTED_DONATION
  attribute :is_log_notifications_enabled, :boolean, default: true
  attribute :is_maintenance_mode, :boolean, default: true
  attribute :is_pickup_notice_enabled, :boolean, default: false
  attribute :is_reservations_export_schedule_enabled, :boolean, default: false
  attribute :reservations_export_time, :string, default: DEFAULT_RESERVATIONS_EXPORT_TIME

  normalizes :phone_default_country, with: ->(country) { country.to_s.strip.upcase.presence }

  validates :organization_name, presence: true
  validates :default_country, presence: true
  validates :phone_default_country, presence: true, length: { is: 2 }
  validates :event_pickup_start, :event_pickup_end, :event_sign_up_deadline, presence: { message: "date and time can't be blank" }
  validates :home_page_header, presence: true, if: ->(setting) { setting.organization_name.present? }
  validates :time_zone, inclusion: { in: AVAILABLE_TIME_ZONES }
  validates :marketing_email_cooldown_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :contact_retention_months, numericality: { only_integer: true, greater_than: 0 }
  validates :reservations_export_email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }, allow_blank: true
  validates :reservations_export_time, format: { with: RESERVATIONS_EXPORT_TIME_FORMAT, message: "must be a valid time (HH:MM)" }, allow_blank: true
  validate :reservations_export_schedule_is_complete
  validate :home_page_image_is_available
  validate :mailer_logo_is_available

  before_validation :apply_defaults
  after_update_commit :log_configuration_changes

  def apply_defaults
    self.home_page_header = "#{organization_name.strip} Tree Recycle" if organization_name.present? && home_page_header.blank?
    self.time_zone = DEFAULT_TIME_ZONE if time_zone.blank?
    self.default_country = DEFAULT_COUNTRY if default_country.blank?
    self.phone_default_country = DEFAULT_PHONE_COUNTRY if phone_default_country.blank?
    self.email_batch_quantity = DEFAULT_EMAIL_BATCH_QUANTITY if email_batch_quantity.blank?
    self.marketing_email_cooldown_days = DEFAULT_MARKETING_COOLDOWN_DAYS if marketing_email_cooldown_days.blank?
    self.contact_retention_months = DEFAULT_RETENTION_MONTHS if contact_retention_months.blank?
  end

  def suggested_donation_amount
    suggested_donation.presence || DEFAULT_SUGGESTED_DONATION
  end

  def about_event_description_text
    about_event_description.presence || DEFAULT_ABOUT_EVENT_DESCRIPTION
  end

  def pickup_instructions_text
    on_day_of_pickup_instructions.presence || DEFAULT_PICKUP_INSTRUCTIONS
  end

  def reservations_closed_message_text
    reservations_closed_message.presence || DEFAULT_RESERVATIONS_CLOSED_MESSAGE
  end

  # The home page form is shown only while reservations are open and the
  # pickup notice is off. The notice replaces the form during pickups.
  def accepting_reservations?
    is_reservations_open? && !is_pickup_notice_enabled?
  end

  def donations_page_content_text
    donations_page_content.presence || DEFAULT_DONATIONS_PAGE_CONTENT
  end

  def donations_page_how_to_donate_text
    donations_page_how_to_donate.presence || DEFAULT_DONATIONS_PAGE_HOW_TO_DONATE
  end

  def donations_new_page_content_text
    donations_new_page_content.presence || DEFAULT_DONATIONS_NEW_PAGE_CONTENT
  end

  def donations_success_page_content_text
    donations_success_page_content.presence || DEFAULT_DONATIONS_SUCCESS_PAGE_CONTENT
  end

  def home_page_image_name
    home_page_image.presence || DEFAULT_HOME_PAGE_IMAGE
  end

  # Logo system emails use when the mailer does not pass an explicit filename.
  def mailer_logo_name
    mailer_logo.presence || DEFAULT_MAILER_LOGO
  end

  def self.instance
    first
  end

  # Select options for the daily export send time, labeled like "6:00 AM".
  def self.reservations_export_time_options
    RESERVATIONS_EXPORT_TIMES.map do |time|
      [ Time.parse(time).strftime("%-l:%M %p"), time ]
    end
  end

  def reservations_export_schedule_configured?
    is_reservations_export_schedule_enabled? &&
      reservations_export_email.present? && reservations_export_time.present?
  end

  # True when the daily export should be sent for the given local time: the
  # schedule is enabled, the send time has passed today, and it has not
  # already been sent today.
  def reservations_export_due?(now = Time.current)
    return false unless reservations_export_schedule_configured?

    hour, minute = reservations_export_time.split(":").map(&:to_i)
    return false if now < now.beginning_of_day + hour.hours + minute.minutes

    last_sent = reservations_export_last_sent_at&.in_time_zone(now.time_zone)
    last_sent.nil? || last_sent.to_date != now.to_date
  end

  def mark_reservations_export_sent!(at = Time.current)
    update!(reservations_export_last_sent_at: at)
  end

  def sms_configured?
    twilio_account_sid.present? && twilio_auth_token.present? && twilio_from_number.present?
  end

  def missing_required_settings
    missing = REQUIRED_SETTINGS.select { |item| public_send(item[:attribute]).blank? }

    if is_emailing_enabled?
      missing.concat(missing_email_settings)
    end

    if is_sms_enabled?
      missing << { attribute: :twilio_account_sid, label: "Twilio Account SID", section: "sms" } if twilio_account_sid.blank?
      missing << { attribute: :twilio_auth_token, label: "Twilio Auth Token", section: "sms" } if twilio_auth_token.blank?
      missing << { attribute: :twilio_from_number, label: "Twilio From Number", section: "sms" } if twilio_from_number.blank?
    end

    if is_donations_enabled?
      missing << { attribute: :stripe_secret_key, label: "Stripe Secret Key", section: "donations" } if stripe_secret_key.blank?
      missing << { attribute: :stripe_price_id, label: "Stripe Price ID", section: "donations" } if stripe_price_id.blank?
    end

    if is_routing_enabled?
      missing << { attribute: :aws_access_key_id, label: "AWS Access Key ID", section: "location_services" } if aws_access_key_id.blank?
      missing << { attribute: :aws_secret_access_key, label: "AWS Secret Access Key", section: "location_services" } if aws_secret_access_key.blank?
      missing << { attribute: :aws_region, label: "AWS Region", section: "location_services" } if aws_region.blank?
      missing << { attribute: :aws_location_index_name, label: "AWS Place Index Name", section: "location_services" } if aws_location_index_name.blank?
    end

    if is_pickups_site_enabled? && driver_secret_key.blank?
      missing << { attribute: :driver_secret_key, label: "Pickups Portal Password", section: "pickups" }
    end

    missing
  end

  def required_data_complete?
    missing_required_settings.empty?
  end

  def sms_quick_response_list
    sms_quick_responses.to_s.split("\n").map(&:strip).reject(&:blank?)
  end

  def apply_phone_default_country!
    Phonelib.default_country = phone_default_country.presence || "US"
  end

  # URL options derived from the configured Site URL, used to build public
  # links (mailer URLs, webhook endpoints). Returns {} when no valid host is
  # configured so callers fall back to the Rails default URL options. The
  # :port key is always set (nil for default ports) so route helpers render
  # exactly this host instead of merging the current request's port.
  def site_url_options
    url = site_url.to_s.strip
    return {} if url.blank?

    url = "https://#{url}" unless url.match?(%r{\Ahttps?://}i)
    uri = URI.parse(url)
    return {} if uri.host.blank?

    options = { host: uri.host, protocol: uri.scheme, port: nil }
    options[:port] = uri.port if uri.port && uri.port != uri.default_port
    options
  rescue URI::InvalidURIError
    {}
  end

  def missing_email_settings
    REQUIRED_EMAIL_SETTINGS.select { |item| public_send(item[:attribute]).blank? }
  end

  def email_from_configured?
    email_from_address.present?
  end

  # Number of marketing emails that will actually be sent for the given number of eligible contacts.
  def email_batch_size(eligible_count)
    [ email_batch_quantity.to_i, eligible_count.to_i ].min
  end

  def email_configured?
    missing_email_settings.empty?
  end

  def email_configuration_alert(purpose: "sending emails")
    missing = missing_email_settings.map { |item| item[:label] }
    return if missing.empty?

    "Email settings are incomplete. Add #{missing.to_sentence} in Settings before #{purpose}."
  end

  def stripe_configured?
    stripe_secret_key.present? && stripe_price_id.present?
  end

  def location_service_configured?
    aws_access_key_id.present? && aws_secret_access_key.present? &&
      aws_region.present? && aws_location_index_name.present?
  end

  def configure_location_service!
    return false unless location_service_configured?

    apply_location_client!
    true
  end

  # Credentials and region are enough to ask Amazon. A blank place index is
  # sent through so the SDK or the service can reject it, instead of stopping
  # locally and reporting a successful geocode.
  def prepare_location_search!
    return false unless aws_access_key_id.present? && aws_secret_access_key.present? && aws_region.present?

    apply_location_client!
    true
  end

  # Options for SearchPlaceIndexForText. Amazon Location allows a bias
  # position or a bounding box, not both. The box keeps matches inside the
  # area covered by route boundaries.
  def location_search_options
    options = { max_results: 5 }
    box = location_filter_bbox
    return options unless box

    options[:filter_b_box] = box
    options
  end

  def location_filter_bbox
    latitudes = Point.where.not(latitude: nil).pluck(:latitude)
    longitudes = Point.where.not(longitude: nil).pluck(:longitude)
    return if latitudes.empty? || longitudes.empty?

    pad = 0.05
    [
      longitudes.min.to_f - pad,
      latitudes.min.to_f - pad,
      longitudes.max.to_f + pad,
      latitudes.max.to_f + pad
    ]
  end

  def smtp_settings
    settings = {
      address: smtp_address,
      port: smtp_port,
      user_name: smtp_user_name.presence,
      password: smtp_password.presence,
      authentication: smtp_authentication.presence&.to_sym
    }.compact

    case smtp_encryption
    when "tls"
      settings[:tls] = true
    when "none"
      settings[:enable_starttls_auto] = false
    else
      settings[:enable_starttls_auto] = true
    end

    settings
  end

  private

  def log_configuration_changes
    changes = saved_changes.except("updated_at")
    return if changes.empty?

    Log.create(
      log_type: "configuration",
      severity: "info",
      handled: true,
      message: "Settings updated: #{changes.keys.sort.join(', ')}",
      context: {
        user: Current.user&.email,
        changes: sanitized_setting_changes(changes)
      }
    )
  rescue StandardError => e
    Rails.logger.error("Settings change could not be logged: #{e.class}: #{e.message}")
  end

  def sanitized_setting_changes(changes)
    changes.each_with_object({}) do |(attribute, (before, after)), result|
      if SENSITIVE_SETTING_ATTRIBUTES.include?(attribute.to_s)
        result[attribute] = [ "[FILTERED]", "[FILTERED]" ]
      else
        result[attribute] = [ before, after ]
      end
    end
  end

  # The Geocoder Amazon Location client reads the region from api_key.
  # Aws.config and ~/.aws/config are fallbacks, which exist in development
  # and are absent in the production container.
  def apply_location_client!
    Geocoder.configure(
      timeout: 10,
      lookup: :amazon_location_service,
      amazon_location_service: {
        index_name: aws_location_index_name,
        api_key: {
          region: aws_region,
          access_key_id: aws_access_key_id,
          secret_access_key: aws_secret_access_key
        }
      }
    )
    Aws.config.update(region: aws_region)
    reset_location_client!
  end

  # The lookup memoizes its AWS client. Drop it so a region or key change
  # is used on the next search instead of the client built at boot.
  def reset_location_client!
    services = Geocoder::Lookup.instance_variable_get(:@services)
    lookup = services&.[](:amazon_location_service)
    return unless lookup&.instance_variable_defined?(:@client)

    lookup.remove_instance_variable(:@client)
  end

  def reservations_export_schedule_is_complete
    return unless is_reservations_export_schedule_enabled?

    errors.add(:reservations_export_email, "is required to schedule the daily export") if reservations_export_email.blank?
    errors.add(:reservations_export_time, "is required to schedule the daily export") if reservations_export_time.blank?
  end

  def home_page_image_is_available
    return if home_page_image.blank?
    return if MarketingEmailTemplate.available_images.include?(home_page_image)

    errors.add(:home_page_image, "is not an available image")
  end

  def mailer_logo_is_available
    return if mailer_logo.blank?
    return if MarketingEmailTemplate.available_images.include?(mailer_logo)

    errors.add(:mailer_logo, "is not an available image")
  end
end
