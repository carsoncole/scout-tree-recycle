class Admin::MarketingController < Admin::BaseController
  def index
    @pagy, @contacts = pagy(Contact.order(:email))
    @marketing_1_count = Contact.where(marketing_1_email_sent_at: nil).count
    @marketing_2_count = Contact.where(marketing_2_email_sent_at: nil).count
    @marketing_email_templates = MarketingEmailTemplate.where(name: MarketingEmailTemplate::MARKETING_EMAIL_NAMES).index_by(&:name)

    setting = Setting.instance
    @email_batch_quantity = setting.email_batch_quantity
    if !setting.is_emailing_enabled?
      flash.now[:alert] = "Emailing is disabled. Enable email notifications in Settings to send marketing emails."
    elsif (message = setting.email_configuration_alert(purpose: "sending marketing emails"))
      flash.now[:alert] = message
    end
  end

  def send_marketing_email_1
    setting = Setting.instance

    if !setting.is_emailing_enabled?
      redirect_to admin_marketing_index_path, alert: "Emailing is disabled. Enable email notifications in Settings to send marketing emails."
    elsif (message = setting.email_configuration_alert(purpose: "sending marketing emails"))
      redirect_to admin_marketing_index_path, alert: message
    elsif MarketingEmailTemplate.published.find_by(name: "marketing_email_1").nil?
      redirect_to admin_marketing_index_path, alert: "Marketing email 1 is not published. Edit the template and publish it before sending."
    else
      count_to_be_sent = Contact.where(marketing_1_email_sent_at: nil).count
      if count_to_be_sent.zero?
        redirect_to admin_marketing_index_path, alert: "No contacts are eligible for Marketing email 1."
      else
        SendMarketingEmail1Job.perform_later
        queued_count = [ setting.email_batch_quantity, count_to_be_sent ].min
        redirect_to admin_marketing_index_path, notice: "#{queued_count} of #{count_to_be_sent} marketing #1 emails queued to be sent."
      end
    end
  end

  def send_marketing_email_2
    setting = Setting.instance

    if !setting.is_emailing_enabled?
      redirect_to admin_marketing_index_path, alert: "Emailing is disabled. Enable emailing in Settings to send marketing emails."
    elsif (message = setting.email_configuration_alert(purpose: "sending marketing emails"))
      redirect_to admin_marketing_index_path, alert: message
    elsif MarketingEmailTemplate.published.find_by(name: "marketing_email_2").nil?
      redirect_to admin_marketing_index_path, alert: "Marketing email 2 is not published. Edit the template and publish it before sending."
    else
      count_to_be_sent = Contact.where(marketing_2_email_sent_at: nil).count
      if count_to_be_sent.zero?
        redirect_to admin_marketing_index_path, alert: "No contacts are eligible for Marketing email 2."
      else
        SendMarketingEmail2Job.perform_later
        queued_count = [ setting.email_batch_quantity, count_to_be_sent ].min
        redirect_to admin_marketing_index_path, notice: "#{queued_count} of #{count_to_be_sent} marketing #2 emails queued to be sent."
      end
    end
  end
end
