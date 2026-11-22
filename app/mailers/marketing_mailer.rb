# Marketing emails are rendered from MarketingEmailTemplate records with
# Liquid. Premailer Rails inlines the templates' stylesheets at delivery time.
class MarketingMailer < ApplicationMailer
  before_action :set_contact, except: :test_email
  after_deliver :mark_marketing_email_sent

  def marketing_email_1
    setting = Setting.instance
    return unless setting.is_emailing_enabled?
    return unless setting.email_from_configured?
    return if @contact.is_unsubscribed_from_marketing?
    return if @contact.marketing_1_email_sent_at?

    deliver_template("marketing_email_1", sent_at_attribute: :marketing_1_email_sent_at)
  end

  def marketing_email_2
    setting = Setting.instance
    return unless setting.is_emailing_enabled?
    return unless setting.email_from_configured?
    return if @contact.is_unsubscribed_from_marketing?
    return if @contact.marketing_2_email_sent_at?

    deliver_template("marketing_email_2", sent_at_attribute: :marketing_2_email_sent_at)
  end

  # Sends the current draft (or published version) to an admin for review.
  # This intentionally does not require emailing to be enabled or update the
  # contact's marketing sent timestamps.
  def test_email
    @template = MarketingEmailTemplate.find(params[:template_id])
    @contact = Contact.find_by(id: params[:contact_id]) || MarketingEmailTemplate.sample_contact
    @setting = Setting.instance
    source = params[:source].to_s == "published" ? :published : :draft

    @email_assigns = MarketingEmailTemplate::Renderer.new(contact: @contact, setting: @setting).assigns
    @email_html = @template.render_message_html(@email_assigns, source: source)
    @email_text = @template.render_message_text(@email_assigns, source: source)
    subject = @template.render_subject(@email_assigns, source: source)

    recipient = params[:email].presence || @contact.email
    return if Contact.blocked_marketing_email_domain?(recipient)

    from = source == :published ? @template.published_from : @template.from
    headers = {
      to: recipient,
      subject: "[TEST] #{subject}",
      template_name: "templated_email"
    }
    headers[:from] = from if from.present?

    mail(**headers)
  end

  private

  def set_contact
    @contact = if params[:contact_id].present?
      Contact.find(params[:contact_id])
    else
      MarketingEmailTemplate.sample_contact
    end
  end

  def deliver_template(template_name, sent_at_attribute: nil)
    @template = MarketingEmailTemplate.published.find_by(name: template_name)
    return false if @template.nil?
    return false if Contact.blocked_marketing_email_domain?(@contact.email)

    @setting = Setting.instance
    @email_assigns = MarketingEmailTemplate::Renderer.new(contact: @contact, setting: @setting).assigns

    headers = {
      to: @contact.email,
      subject: @template.render_subject(@email_assigns, source: :published),
      template_name: "templated_email"
    }
    headers[:from] = @template.published_from if @template.published_from.present?
    if @contact&.persisted?
      headers["List-Unsubscribe"] = "<#{unsubscribe_contact_url(@contact)}>"
      headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
    end

    @email_html = @template.render_message_html(@email_assigns, source: :published)
    @email_text = @template.render_message_text(@email_assigns, source: :published)
    @marketing_email_sent_at_attribute = sent_at_attribute

    mail(**headers)
    true
  end

  # Only mark the contact after the delivery method succeeds. Building the
  # message is not enough: SMTP/test delivery can fail after the mailer action
  # runs, and previously that left contacts marked as sent even though nothing
  # was delivered.
  def mark_marketing_email_sent
    return if @marketing_email_sent_at_attribute.blank?
    return if @contact.blank? || @contact.id.blank?

    Contact.where(id: @contact.id).update_all(@marketing_email_sent_at_attribute => Time.current, updated_at: Time.current)
  end
end
