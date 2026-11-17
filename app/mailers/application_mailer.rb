class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper
  layout "mailer"

  LOGO_FILENAME = "fleur-de-lis-2024-logo-4c-bc.png"

  helper_method :email_logo_tag, :email_logo_src

  before_action :apply_site_url
  before_action :apply_email_settings
  before_action :configure_phonelib
  around_action :use_setting_time_zone

  def email_logo_tag(width: 140, alt: nil, style: nil, filename: LOGO_FILENAME)
    attributes = []
    attributes << %(alt="#{ERB::Util.html_escape(alt)}") if alt.present?
    attributes << %(style="#{ERB::Util.html_escape(style)}") if style.present?
    extra = attributes.empty? ? "" : " #{attributes.join(" ")}"

    %(<img src="#{ERB::Util.html_escape(email_logo_src(filename: filename))}" width="#{width.to_i}"#{extra}>).html_safe
  end

  # Attaches the logo inline and returns its CID URL. Unknown or blank
  # filenames fall back to the built-in logo.
  def email_logo_src(filename: LOGO_FILENAME)
    filename = safe_logo_filename(filename)
    attachments.inline[filename] ||= File.binread(Rails.root.join("app/assets/images", filename))
    attachments[filename].url
  end

  private

  def safe_logo_filename(filename)
    return LOGO_FILENAME if filename.blank?
    return LOGO_FILENAME unless filename.to_s == File.basename(filename.to_s)
    return LOGO_FILENAME unless File.file?(Rails.root.join("app/assets/images", filename))

    filename
  end

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
