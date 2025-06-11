class Admin::SettingsController < Admin::BaseController
  allow_unauthenticated_access only: [:new, :create]

  def index
    @unviewed_logs_count = Log.where(is_viewed: false).count
  end

  def new
    if Setting.first.present?
      redirect_to admin_settings_path
    else
      @setting = Setting.new
    end
  end

  def create
    @setting = Setting.new(setting_params)
    if @setting.save
      unless User.exists?(role: "admin")
        User.create!(email: "admin@example.com", password: "password", role: "admin")
      end
      redirect_to admin_settings_path, notice: "Settings saved. Admin user created with email admin@example.com and password 'password'."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if Current.user.admin?
      if helpers.setting.update(setting_params)
        redirect_to admin_settings_path, notice: "Settings were successfully updated."
      else
        render :index, status: :unprocessable_entity
      end
    else
      redirect_to admin_settings_path, alert: "You are not authorized to update settings."
    end
  end

  def toggle
    if Current.user.admin?
      setting = helpers.setting
      setting[params[:setting]] = params[:value]

      if setting.save
        RouteReservationsJob.perform_later if setting.is_routing_enabled? && params[:setting] == "is_routing_enabled"
        render json: { success: true }
      else
        render json: { success: false, errors: setting.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { success: false, errors: [ "You are not authorized to update settings." ] }, status: :unauthorized
    end
  end

  private

  def setting_params
    params.require(:setting).permit(
      :site_title,
      :home_page_header,
      :organization_name,
      :organization_url,
      :site_description,
      :reservations_closed_message,
      :event_pickup_start,
      :event_pickup_end,
      :event_sign_up_deadline,
      :default_city,
      :default_state,
      :country,
      :about_event_description,
      :on_day_of_pickup_instructions,
      :is_reservations_open,
      :is_emailing_enabled,
      :is_sms_enabled,
      :is_pickups_site_enabled,
      :is_routing_enabled,
      :contact_name,
      :contact_email,
      :contact_phone,
      :contact_sms,
      :driver_secret_key,
      :description,
      :email_batch_quantity,
      :time_zone
    )
  end
end
