class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper
  default from: EMAIL_FROM
  layout "mailer"

  before_action :apply_site_url
  before_action :apply_email_settings

  private

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
  rescue URI::InvalidURIError
    Rails.logger.warn("Invalid site URL configured: #{setting&.site_url}")
  end

  def apply_email_settings
    setting = Setting.instance
    return unless setting&.email_configured?

    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = setting.smtp_settings
    self.class.default from: setting.email_from_address
  end
end
