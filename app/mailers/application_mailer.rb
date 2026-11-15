class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper
  layout "mailer"

  before_action :apply_site_url
  before_action :apply_email_settings
  before_action :configure_phonelib
  around_action :use_setting_time_zone

  private

  def configure_phonelib
    Setting.instance&.apply_phone_default_country!
  end

  def use_setting_time_zone(&block)
    zone_name = Setting.instance&.time_zone
    zone = ActiveSupport::TimeZone[zone_name] if zone_name.present?
    zone ? Time.use_zone(zone, &block) : block.call
  end

  def apply_site_url
    setting = Setting.instance
    return if setting&.site_url.blank?

    site_url = setting.site_url.strip
    site_url = "https://#{site_url}" unless site_url.match?(%r{\Ahttps?://}i)
    uri = URI.parse(site_url)
    return if uri.host.blank?

    options = { host: uri.host, protocol: uri.scheme }
    options[:port] = uri.port if uri.port && uri.port != uri.default_port
    ActionMailer::Base.default_url_options = options
  rescue URI::InvalidURIError => e
    Rails.logger.warn("Invalid site URL configured: #{setting&.site_url}")
    Rails.error.report(e, handled: true, severity: :warning, context: { site_url: setting&.site_url })
  end

  def apply_email_settings
    setting = Setting.instance
    return unless setting

    self.class.default from: setting.email_from_address if setting.email_from_address.present?
    return unless setting.email_configured?

    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = setting.smtp_settings
  end
end
