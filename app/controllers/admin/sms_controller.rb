class Admin::SmsController < Admin::BaseController
  def index
    @smses_by_phone = Sms.order(created_at: :desc)
                         .group_by(&:phone)
                         .transform_values { |messages| messages.sort_by(&:created_at) }
    flash.now[:alert] = "SMS messaging is disabled. Enable SMS in Settings to send messages." unless helpers.setting.is_sms_enabled?
  end

  def mark_viewed
    phone = params[:phone]
    Sms.where(phone: phone, viewed: false).update_all(viewed: true)
    head :ok
  end

  def destroy
    phone = params[:phone]
    Sms.where(phone: phone).destroy_all
    redirect_to admin_sms_index_path, notice: "Thread deleted successfully."
  end

  def create
    if helpers.setting.is_sms_enabled?
      @sms = Sms.new(sms_params)
      @sms.direction = :outgoing

      if @sms.save
        redirect_to admin_sms_index_path, notice: "Message sent successfully."
      else
        redirect_to admin_sms_index_path, alert: "Failed to send message: #{@sms.errors.full_messages.join(', ')}"
      end
    else
      redirect_to admin_sms_index_path, alert: "SMS messaging is disabled. Enable SMS in Settings to send messages."
    end
  end

  private

  def sms_params
    params.require(:sms).permit(:phone, :body)
  end
end
