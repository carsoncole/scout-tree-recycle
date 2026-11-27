class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper
  layout "mailer"

  # Built-in fallback used when no Setting row exists. The default logo for
  # system emails normally comes from Setting#mailer_logo_name.
  LOGO_FILENAME = "fleur-de-lis-2024-logo-4c-bc-icon.png"

  helper_method :email_logo_tag, :email_logo_src, :default_page_name

  before_action :apply_site_url
  before_action :apply_email_settings
  before_action :configure_phonelib
  around_action :use_setting_time_zone
  # Not a header. The mail archive reads this after a successful delivery.
  after_action :remember_mail_action

  def email_logo_tag(width: ReservationEmailTemplate::LOGO_WIDTH, alt: nil, style: nil, filename: nil)
    attributes = []
    attributes << %(alt="#{ERB::Util.html_escape(alt)}") if alt.present?
    attributes << %(style="#{ERB::Util.html_escape(style)}") if style.present?
    extra = attributes.empty? ? "" : " #{attributes.join(" ")}"

    %(<img src="#{ERB::Util.html_escape(email_logo_src(filename: filename))}" width="#{width.to_i}"#{extra}>).html_safe
  end

  # Attaches the logo and returns its cid: URL. Gmail strips data: URIs, so
  # the image has to travel as an inline MIME part. A blank filename uses the
  # default mailer logo from Settings; unknown filenames fall back to it too.
  def email_logo_src(filename: nil)
    inline_email_image_src(safe_logo_filename(filename))
  end

  # Replaces email-image markers left by the template renderer. Only markers
  # that are still in the HTML become attachments.
  def embed_email_images(html)
    html.to_s.gsub(/#{Regexp.escape(EmailImageLibrary::MARKER_PREFIX)}([a-z0-9_]+)/) do
      filename = EmailImageLibrary.image_variables[Regexp.last_match(1)]
      filename.present? ? inline_email_image_src(filename) : Regexp.last_match(0)
    end
  end

  def inline_email_image_src(filename)
    filename = filename.to_s
    return "" unless filename == File.basename(filename)
    return "" unless EmailImageLibrary.image_file?(filename)

    attach_inline_email_image(filename).url
  end

  private

  # Mail::AttachmentsList#inline stays on for every later attachment. Put it
  # back so a file added after an image is not sent inline.
  def attach_inline_email_image(filename)
    existing = attachments[filename]
    return existing if existing

    path = EmailImageLibrary::DIRECTORY.join(filename)
    attachments.inline[filename] = {
      mime_type: Marcel::MimeType.for(path, name: filename),
      content: File.binread(path)
    }
    attachments.instance_variable_set(:@content_disposition_type, "attachment")
    attachments[filename]
  end

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

  def remember_mail_action
    return unless @_mail_was_called

    message.instance_variable_set(:@mails_action, action_name)
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
