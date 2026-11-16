class Admin::SettingsController < Admin::BaseController
  allow_unauthenticated_access only: [ :new, :create ]

  TOGGLEABLE_SETTINGS = %w[
    is_reservations_open
    is_emailing_enabled
    is_log_notifications_enabled
    is_sms_enabled
    is_pickups_site_enabled
    is_routing_enabled
    is_donations_enabled
  ].freeze

  def index
    @unviewed_logs_count = Log.where(is_viewed: false).count
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
      if Setting.instance.update(setting_params)
        redirect_to admin_settings_path, notice: "Settings were successfully updated."
      else
        render :index, status: :unprocessable_entity
      end
    else
      redirect_to admin_settings_path, alert: "You are not authorized to update settings."
    end
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

  def build_initial_admin_user
    attrs = admin_user_params
    if attrs.values.all?(&:blank?)
      password = SecureRandom.base58(24)
      User.new(email: "admin@example.com", password: password, password_confirmation: password, role: "admin")
    else
      User.new(attrs.merge(role: "admin"))
    end
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
      :is_reservations_open,
      :is_emailing_enabled,
      :is_log_notifications_enabled,
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
