class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper
  layout "mailer"

  # Built-in fallback used when no Setting row exists. The default logo for
  # system emails normally comes from Setting#mailer_logo_name.
  LOGO_FILENAME = "fleur-de-lis-2024-logo-4c-bc.png"

  helper_method :email_logo_tag, :email_logo_src

  before_action :apply_site_url
  before_action :apply_email_settings
  before_action :configure_phonelib
  around_action :use_setting_time_zone

  def email_logo_tag(width: 140, alt: nil, style: nil, filename: nil)
    attributes = []
    attributes << %(alt="#{ERB::Util.html_escape(alt)}") if alt.present?
    attributes << %(style="#{ERB::Util.html_escape(style)}") if style.present?
    extra = attributes.empty? ? "" : " #{attributes.join(" ")}"

    %(<img src="#{ERB::Util.html_escape(email_logo_src(filename: filename))}" width="#{width.to_i}"#{extra}>).html_safe
  end

  # Attaches the logo inline and returns its CID URL. A blank filename uses the
  # default mailer logo from Settings; unknown filenames fall back to it too.
  def email_logo_src(filename: nil)
    filename = safe_logo_filename(filename)
    attachments.inline[filename] ||= File.binread(Rails.root.join("app/assets/images", filename))
    attachments[filename].url
  end

  private

  def safe_logo_filename(filename)
    fallback = default_mailer_logo
    return fallback if filename.blank?
    return fallback unless filename.to_s == File.basename(filename.to_s)
    return fallback unless File.file?(Rails.root.join("app/assets/images", filename))

    filename
  end

  # The admin-configured default logo for system emails, with the built-in
  # logo as the fallback before first-run setup creates the Settings row.
  def default_mailer_logo
    Setting.instance&.mailer_logo_name || LOGO_FILENAME
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

    options = setting.site_url_options
    if options.any?
      ActionMailer::Base.default_url_options = options
    else
      error = URI::InvalidURIError.new("Invalid site URL configured: #{setting.site_url}")
      Rails.logger.warn(error.message)
      Rails.error.report(error, handled: true, severity: :warning, context: { site_url: setting.site_url })
    end
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
