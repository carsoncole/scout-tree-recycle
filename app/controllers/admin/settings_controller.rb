class Admin::SettingsController < Admin::BaseController
  def index
    @unviewed_logs_count = Log.where(is_viewed: false).count
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
        render json: { success: true }
      else
        render json: { success: false, errors: setting.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { success: false, errors: ["You are not authorized to update settings."] }, status: :unauthorized
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
      :event_pickup,
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
      :driver_secret_key,
      :description,
      :email_batch_quantity,
      :email_from,
      :time_zone
    )
  end
end
