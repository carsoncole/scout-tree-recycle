# OPTIMIZE updating marketing_1_email_sent_at and marketing_2_email_sent_at to be done ONLY if successful. Rescue?
class MarketingMailer < ApplicationMailer
  before_action :set_contact

  def set_contact
    @contact = Contact.find(params[:contact_id])
  end

  def marketing_email_1
    return unless Setting.instance.is_emailing_enabled?
    return if @contact.marketing_1_email_sent_at?
    @setting = setting
    @email_footer = Setting.instance.organization_name
    mail(to: @contact.email, subject: "Tree recycling #{setting.event_pickup_start.strftime('%B %-d')}. Register today.")
    @contact.update(marketing_1_email_sent_at: Time.current)
  end

  def marketing_email_2
    return unless Setting.instance.is_emailing_enabled?
    return if @contact.marketing_2_email_sent_at?
    return if @contact.marketing_email_cooldown_active?
    @setting = setting
    @email_footer = Setting.instance.organization_name
    mail(to: @contact.email, subject: "Last call! Tree recycling #{setting.event_pickup_start.strftime('%B %-d')}. Register today.")
    @contact.update(marketing_2_email_sent_at: Time.current)
  end
end
