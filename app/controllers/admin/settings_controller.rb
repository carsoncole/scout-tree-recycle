class Admin::SettingsController < Admin::BaseController
  def index
  end

  def update
    if helpers.setting.update(setting_params)
      redirect_to admin_settings_path, notice: "Settings were successfully updated."
    else
      render :index, status: :unprocessable_entity
    end
  end

  def toggle
    helpers.setting.update(params[:setting] => params[:value])

    if helpers.setting.save
      render json: { success: true }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.require(:setting).permit(
      :site_title,
      :home_page_header,
      :organization_name,
      :site_description,
      :reservations_closed_message,
      :event_pickup,
      :event_pickup_end,
      :event_sign_up_deadline,
      :default_city,
      :default_state,
      :on_day_of_pickup_instructions,
      :is_reservations_open,
      :is_emailing_enabled,
      :is_sms_enabled,
      :is_driver_site_enabled,
      :contact_name,
      :contact_email,
      :contact_phone,
      :driver_secret_key
    )
  end
end
