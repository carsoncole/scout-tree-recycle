class Admin::SettingsController < Admin::BaseController
  allow_unauthenticated_access only: [ :new, :create ]

  before_action :set_section, only: [ :show, :update ]

  TOGGLEABLE_SETTINGS = %w[
    is_reservations_open
    is_emailing_enabled
    is_log_notifications_enabled
    is_maintenance_mode
    is_sms_enabled
    is_pickups_site_enabled
    is_routing_enabled
    is_donations_enabled
  ].freeze

  def index
  end

  def show
  end

  def new
    if Setting.exists?
      redirect_to admin_settings_path
    else
      @setting = Setting.new
      @admin_user = User.new unless User.exists?(role: "admin")
    end
  end

  def create
    return redirect_to admin_settings_path, alert: "Settings already exist." if Setting.exists?

    @setting = Setting.new(setting_params)
    @admin_user = build_initial_admin_user unless User.exists?(role: "admin")

    setting_valid = @setting.valid?
    admin_valid = @admin_user.nil? || @admin_user.valid?

    if setting_valid && admin_valid
      ActiveRecord::Base.transaction do
        @setting.save!
        @admin_user&.save!
      end

      notice = "Settings saved."
      notice += " Admin user #{@admin_user.email} created." if @admin_user
      redirect_to admin_settings_path, notice: notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if Current.user.admin?
      restoring_thank_you_message = params[:restore_default].present? && params[:return_to] == "admin_thanks"
      attributes = restoring_thank_you_message ? setting_params.merge(thank_you_message: Setting::DEFAULT_THANK_YOU_MESSAGE) : setting_params

      if @setting.update(attributes)
        redirect_to settings_redirect_path, notice: "Settings were successfully updated."
      elsif params[:return_to] == "close_event"
        redirect_to admin_close_event_path, alert: @setting.errors.full_messages.to_sentence
      else
        render :show, status: :unprocessable_entity
      end
    elsif params[:return_to] == "admin_thanks"
      restoring_thank_you_message = params[:restore_default].present?
      attributes = if restoring_thank_you_message
        { thank_you_message: Setting::DEFAULT_THANK_YOU_MESSAGE }
      else
        params.require(:setting).permit(:thank_you_message)
      end

      if @setting.update(attributes)
        redirect_to settings_redirect_path, notice: "Settings were successfully updated."
      else
        redirect_to admin_thanks_path, alert: @setting.errors.full_messages.to_sentence.presence || "Thank you message could not be updated."
      end
    else
      redirect_to admin_settings_path, alert: "You are not authorized to update settings."
    end
  end

  def send_test_email
    unless Current.user.admin?
      return redirect_to admin_settings_section_path("email"), alert: "You are not authorized to test email settings."
    end

    recipient = params[:test_email_address].to_s.strip

    if recipient.blank? || !recipient.match?(URI::MailTo::EMAIL_REGEXP)
      return redirect_to admin_settings_section_path("email"), alert: "Enter a valid email address to receive the test message."
    end

    if (message = Setting.instance.email_configuration_alert(purpose: "sending a test email"))
      return redirect_to admin_settings_section_path("email"), alert: message
    end

    SettingsMailer.test_email(recipient).deliver_now

    redirect_to admin_settings_section_path("email"), notice: "Test email sent to #{recipient}."
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning, context: { email: recipient })
    redirect_to admin_settings_section_path("email"), alert: "Test email could not be sent: #{e.message}"
  end

  def toggle
    unless Current.user.admin?
      return render json: { success: false, errors: [ "You are not authorized to update settings." ] }, status: :unauthorized
    end

    unless TOGGLEABLE_SETTINGS.include?(params[:setting])
      return render json: { success: false, errors: [ "Invalid setting." ] }, status: :unprocessable_entity
    end

    setting = Setting.instance
    setting[params[:setting]] = params[:value]

    if setting.save
      RouteReservationsJob.perform_later if setting.is_routing_enabled? && params[:setting] == "is_routing_enabled"
      render json: { success: true }
    else
      render json: { success: false, errors: setting.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_section
    @section = params[:section].presence || "event"

    unless Setting::SECTIONS.key?(@section)
      return redirect_to admin_settings_path, alert: "Unknown settings section."
    end

    @section_metadata = Setting::SECTIONS.fetch(@section)
    @setting = Setting.instance
    load_section_data
  end

  def load_section_data
    case @section
    when "pickups"
      @drivers_count = Driver.count
      @zones_count = Zone.count
      @routes_count = Route.count
    when "system"
      @unviewed_logs_count = Log.where(is_viewed: false).count
    end
  end

  def settings_redirect_path
    return admin_close_event_path if params[:return_to] == "close_event"
    return admin_thanks_path if params[:return_to] == "admin_thanks"

    if params[:section].present? && Setting::SECTIONS.key?(@section)
      admin_settings_section_path(@section)
    else
      admin_settings_path
    end
  end

  def build_initial_admin_user
    User.new(admin_user_params.merge(role: "admin"))
  end

  def admin_user_params
    params.fetch(:admin_user, {}).permit(:email, :password, :password_confirmation)
  end

  def setting_params
    params.require(:setting).permit(
      :home_page_header,
      :organization_name,
      :organization_url,
      :site_url,
      :home_page_image,
      :time_zone,
      :default_country,
      :phone_default_country,
      :reservations_closed_message,
      :event_pickup_start,
      :event_pickup_end,
      :event_sign_up_deadline,
      :suggested_donation,
      :default_city,
      :default_state,
      :about_event_description,
      :on_day_of_pickup_instructions,
      :donations_page_content,
      :donations_page_how_to_donate,
      :donations_new_page_content,
      :donations_success_page_content,
      :thank_you_message,
      :is_reservations_open,
      :is_emailing_enabled,
      :is_log_notifications_enabled,
      :is_maintenance_mode,
      :is_sms_enabled,
      :is_pickups_site_enabled,
      :is_routing_enabled,
      :is_donations_enabled,
      :contact_name,
      :contact_email,
      :contact_phone,
      :contact_sms,
      :twilio_account_sid,
      :twilio_auth_token,
      :twilio_from_number,
      :sms_quick_responses,
      :missing_tree_sms_message,
      :missing_tree_sms_follow_up_message,
      :email_from_address,
      :marketing_email_cooldown_days,
      :contact_retention_months,
      :smtp_address,
      :smtp_port,
      :smtp_user_name,
      :smtp_password,
      :smtp_authentication,
      :smtp_encryption,
      :stripe_secret_key,
      :stripe_price_id,
      :aws_access_key_id,
      :aws_secret_access_key,
      :aws_region,
      :aws_location_index_name,
      :driver_secret_key,
      :email_batch_quantity
    )
  end
end
