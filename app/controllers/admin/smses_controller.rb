class Admin::SmsesController < Admin::BaseController
  def index
    @smses_by_reservation = Sms.where.not(reservation_id: nil)
                              .order(created_at: :desc)
                              .group_by(&:reservation_id)
    flash.now[:alert] = "SMS messaging is disabled. Enable SMS in Settings to send messages." unless helpers.setting.is_sms_enabled?
  end
end
