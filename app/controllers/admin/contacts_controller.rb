class Admin::ContactsController < Admin::BaseController
  MARKETING_SENDS = {
    1 => {
      template: "marketing_email_1",
      mailer_action: :marketing_email_1,
      disabled: "Emailing is disabled. Enable email notifications in Settings to send marketing emails."
    },
    2 => {
      template: "marketing_email_2",
      mailer_action: :marketing_email_2,
      disabled: "Emailing is disabled. Enable emailing in Settings to send marketing emails."
    }
  }.freeze

  before_action :set_contact, only: [ :show, :edit, :update, :destroy, :clear_marketing_email_1, :clear_marketing_email_2, :send_marketing_email_1, :send_marketing_email_2 ]

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)

    if @contact.save
      redirect_to admin_marketing_index_path, notice: "Contact was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @contact.update(contact_params)
      redirect_to admin_marketing_index_path, notice: "Contact was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy
    redirect_to admin_marketing_index_path, notice: "Contact was successfully deleted."
  end

  def clear_marketing_email_1
    clear_marketing_email!(1)
  end

  def clear_marketing_email_2
    clear_marketing_email!(2)
  end

  def send_marketing_email_1
    send_marketing_email!(1)
  end

  def send_marketing_email_2
    send_marketing_email!(2)
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:name, :email, :mobile, :street, :is_unsubscribed_from_marketing)
  end

  def clear_marketing_email!(marketing_email)
    if @contact.clear_marketing_email!(marketing_email)
      redirect_to admin_marketing_index_path, notice: "Marketing email #{marketing_email} sent date was cleared."
    else
      redirect_to admin_marketing_index_path, alert: "Marketing email #{marketing_email} sent date could not be cleared."
    end
  end

  def send_marketing_email!(number)
    campaign = MARKETING_SENDS.fetch(number)
    setting = Setting.instance

    if !setting.is_emailing_enabled?
      redirect_to admin_marketing_index_path, alert: campaign[:disabled]
    elsif (message = setting.email_configuration_alert(purpose: "sending marketing emails"))
      redirect_to admin_marketing_index_path, alert: message
    elsif MarketingEmailTemplate.published.find_by(name: campaign[:template]).nil?
      redirect_to admin_marketing_index_path, alert: "Marketing email #{number} is not published. Edit the template and publish it before sending."
    elsif !@contact.eligible_for_marketing_email?(number)
      redirect_to admin_marketing_index_path, alert: "Contact is not eligible for Marketing email #{number}."
    else
      MarketingMailer.with(contact_id: @contact.id).public_send(campaign[:mailer_action]).deliver_later
      redirect_to admin_marketing_index_path, notice: "Marketing email #{number} queued for #{@contact.email}."
    end
  end
end
