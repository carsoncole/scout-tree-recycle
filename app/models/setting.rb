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
  DEFAULT_ABOUT_EVENT_DESCRIPTION = "Tree Recycle is a community event where we collect trees and recycle them into mulch. This is our primary fundraiser for the year and all proceeds go to the Troop."
  DEFAULT_PICKUP_INSTRUCTIONS = "To prepare your tree for pick-up, remove all decorations and tinsel from your tree. Prior to pickup, place your tree in a visible location at the curb or where you indicated to us in your reservation. Your tree will be collected and recycled into mulch. We cannot take wreaths, flocked trees, or artificial trees. If we can not find your tree, we will try contacting you by SMS or phone call to make arrangements to attempt another pick-up."
  DEFAULT_THANK_YOU_MESSAGE = "We want to say thank you to our community and to the supporters who make this fundraiser possible. Their generosity supports our Scouting program and the environment."
  DEFAULT_RESERVATIONS_CLOSED_MESSAGE = "Stay tuned for when we open reservations again."
  DEFAULT_HOME_PAGE_IMAGE = "fleur-de-lis-2024-logo-4c-bc.png"

  REQUIRED_SETTINGS = [
    { attribute: :organization_name, label: "Organization Name", section: "organization" },
    { attribute: :site_url, label: "Site URL", section: "site-details" },
    { attribute: :default_city, label: "Default City", section: "event-settings" },
    { attribute: :default_state, label: "Default State", section: "event-settings" },
    { attribute: :event_pickup_start, label: "Event Pickup Start", section: "event-settings" },
    { attribute: :event_pickup_end, label: "Event Pickup End", section: "event-settings" },
    { attribute: :event_sign_up_deadline, label: "Sign Up Deadline", section: "event-settings" }
  ].freeze

  REQUIRED_EMAIL_SETTINGS = [
    { attribute: :email_from_address, label: "Email From Address", section: "email" },
    { attribute: :smtp_address, label: "SMTP Address", section: "email" },
    { attribute: :smtp_port, label: "SMTP Port", section: "email" }
  ].freeze

  attribute :on_day_of_pickup_instructions, :string, default: DEFAULT_PICKUP_INSTRUCTIONS
  attribute :about_event_description, :string, default: DEFAULT_ABOUT_EVENT_DESCRIPTION
  attribute :reservations_closed_message, :string, default: DEFAULT_RESERVATIONS_CLOSED_MESSAGE
  attribute :time_zone, :string, default: DEFAULT_TIME_ZONE
  attribute :suggested_donation, :integer, default: DEFAULT_SUGGESTED_DONATION
  attribute :is_log_notifications_enabled, :boolean, default: true

  normalizes :phone_default_country, with: ->(country) { country.to_s.strip.upcase.presence }

  validates :organization_name, presence: true
  validates :default_country, presence: true
  validates :phone_default_country, presence: true, length: { is: 2 }
  validates :event_pickup_start, :event_pickup_end, :event_sign_up_deadline, presence: { message: "date and time can't be blank" }
  validates :home_page_header, presence: true, if: ->(setting) { setting.organization_name.present? }
  validates :time_zone, inclusion: { in: AVAILABLE_TIME_ZONES }
  validates :marketing_email_cooldown_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :contact_retention_months, numericality: { only_integer: true, greater_than: 0 }
  validate :home_page_image_is_available

  before_validation :apply_defaults

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

  def home_page_image_name
    home_page_image.presence || DEFAULT_HOME_PAGE_IMAGE
  end

  def self.instance
    first
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
      missing << { attribute: :aws_access_key_id, label: "AWS Access Key ID", section: "location-services" } if aws_access_key_id.blank?
      missing << { attribute: :aws_secret_access_key, label: "AWS Secret Access Key", section: "location-services" } if aws_secret_access_key.blank?
      missing << { attribute: :aws_region, label: "AWS Region", section: "location-services" } if aws_region.blank?
      missing << { attribute: :aws_location_index_name, label: "AWS Place Index Name", section: "location-services" } if aws_location_index_name.blank?
    end

    if is_pickups_site_enabled? && driver_secret_key.blank?
      missing << { attribute: :driver_secret_key, label: "Pickups Portal Password", section: "tree-pickups" }
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

    Geocoder.configure(
      timeout: 10,
      lookup: :amazon_location_service,
      amazon_location_service: {
        index_name: aws_location_index_name,
        api_key: {
          access_key_id: aws_access_key_id,
          secret_access_key: aws_secret_access_key
        }
      }
    )
    Aws.config.update(region: aws_region)
    true
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

  def home_page_image_is_available
    return if home_page_image.blank?
    return if MarketingEmailTemplate.available_images.include?(home_page_image)

    errors.add(:home_page_image, "is not an available image")
  end
end
