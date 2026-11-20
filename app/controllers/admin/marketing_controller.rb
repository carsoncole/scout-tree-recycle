class Admin::MarketingController < Admin::BaseController
  include EmailTemplateResponses

  MARKETING_SENDS = {
    1 => {
      disabled: "Emailing is disabled. Enable email notifications in Settings to send marketing emails.",
      job: SendMarketingEmail1Job,
      template: "marketing_email_1"
    },
    2 => {
      disabled: "Emailing is disabled. Enable emailing in Settings to send marketing emails.",
      job: SendMarketingEmail2Job,
      template: "marketing_email_2"
    }
  }.freeze

  def index
    @pagy, @contacts = pagy(Contact.order(:email))
    @marketing_1_count = Contact.where(marketing_1_email_sent_at: nil).count
    @marketing_2_count = Contact.where(marketing_2_email_sent_at: nil).count
    @marketing_email_templates = MarketingEmailTemplate.where(name: MarketingEmailTemplate::MARKETING_EMAIL_NAMES).index_by(&:name)

    setting = Setting.instance
    @email_batch_quantity = setting.email_batch_quantity
    @marketing_1_batch_size = setting.email_batch_size(@marketing_1_count)
    @marketing_2_batch_size = setting.email_batch_size(@marketing_2_count)
    if !setting.is_emailing_enabled?
      flash.now[:alert] = "Emailing is disabled. Enable email notifications in Settings to send marketing emails."
    elsif (message = setting.email_configuration_alert(purpose: "sending marketing emails"))
      flash.now[:alert] = message
    end
  end

  def send_marketing_email_1
    queue_marketing_email(1)
  end

  def send_marketing_email_2
    queue_marketing_email(2)
  end

  # Sends the published marketing email to an admin address so they can see
  # exactly what contacts will receive. Test sends do not mark contacts as sent.
  def send_test
    template = marketing_email_template(params[:template_name])
    unless template
      redirect_to admin_marketing_index_path, alert: "Choose a marketing email before sending a test."
      return
    end

    email = validated_test_email(admin_marketing_index_path)
    return unless email

    unless template.published?
      redirect_to admin_marketing_index_path, alert: "#{template.name.humanize} is not published. Edit the template and publish it before sending a test."
      return
    end

    contact = find_contact(params[:contact_id]) || MarketingEmailTemplate.sample_contact

    MarketingMailer.with(
      template_id: template.id,
      contact_id: contact.id,
      email: email,
      source: :published
    ).test_email.deliver_now

    redirect_to admin_marketing_index_path, notice: "Test email sent to #{email}."
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning, context: { template_name: params[:template_name], email: params[:email] })
    redirect_to admin_marketing_index_path, alert: "Test email could not be sent: #{e.message}"
  end

  private

  def queue_marketing_email(number)
    campaign = MARKETING_SENDS.fetch(number)
    setting = Setting.instance

    if !setting.is_emailing_enabled?
      redirect_to admin_marketing_index_path, alert: campaign[:disabled]
    elsif (message = setting.email_configuration_alert(purpose: "sending marketing emails"))
      redirect_to admin_marketing_index_path, alert: message
    elsif MarketingEmailTemplate.published.find_by(name: campaign[:template]).nil?
      redirect_to admin_marketing_index_path, alert: "Marketing email #{number} is not published. Edit the template and publish it before sending."
    else
      count_to_be_sent = Contact.where(Contact::MARKETING_EMAIL_COLUMNS.fetch(number) => nil).count
      if count_to_be_sent.zero?
        redirect_to admin_marketing_index_path, alert: "No contacts are eligible for Marketing email #{number}."
      else
        campaign[:job].perform_later
        queued_count = setting.email_batch_size(count_to_be_sent)
        redirect_to admin_marketing_index_path, notice: "#{queued_count} of #{count_to_be_sent} marketing ##{number} emails queued to be sent."
      end
    end
  end

  def marketing_email_template(name)
    name = name.to_s
    return unless MarketingEmailTemplate::MARKETING_EMAIL_NAMES.include?(name)

    MarketingEmailTemplate.find_by(name: name)
  end

  def find_contact(id)
    return if id.blank?

    Contact.find_by(id: id)
  rescue ActiveRecord::StatementInvalid
    nil
  end
end
