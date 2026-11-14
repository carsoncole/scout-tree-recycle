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

  attribute :on_day_of_pickup_instructions, :string, default: "To prepare your tree for pick-up, remove all decorations and tinsel from your tree. Prior to pickup, place your tree in a visible location at the curb or where you indicated to us in your reservation. Your tree will be collected and recycled into mulch. We cannot take wreaths, flocked trees, or artificial trees. If we can not find your tree, we will try contacting you by SMS or phone call to make arrangements to attempt another pick-up."
  attribute :about_event_description, :string, default: "Tree Recycle is a community event where we collect trees and recycle them into mulch. This is our primary fundraiser for the year and all proceeds go to the Troop."
  attribute :reservations_closed_message, :string, default: "Stay tuned for when we open reservations again."
  attribute :time_zone, :string, default: "Pacific Time (US & Canada)"
  attribute :suggested_donation, :integer, default: 25

  validates :organization_name, presence: true
  validates :default_city, :default_state, :default_country, presence: true
  validates :event_pickup_start, :event_pickup_end, :event_sign_up_deadline, presence: { message: "date and time can't be blank" }
  validates :home_page_header, presence: true, if: ->(setting) { setting.organization_name.present? }
  validates :about_event_description, presence: true
  validates :on_day_of_pickup_instructions, presence: true
  validates :time_zone, inclusion: { in: AVAILABLE_TIME_ZONES }

  before_validation :set_defaults, on: :create

  def set_defaults
    return unless self.organization_name.present?
    self.home_page_header = self.organization_name.strip + " Tree Recycle"
  end

  def self.instance
    first
  end

  def sms_configured?
    twilio_account_sid.present? && twilio_auth_token.present? && twilio_from_number.present?
  end

  def email_configured?
    email_from_address.present? && smtp_address.present? && smtp_port.present?
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
end
