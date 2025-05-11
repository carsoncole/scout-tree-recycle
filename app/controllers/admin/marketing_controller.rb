class Admin::MarketingController < Admin::BaseController
  def index
    @pagy, @prior_reservations = pagy(PriorReservation.order(:email))
    @marketing_1_count = PriorReservation.where(marketing_1_email_sent_at: nil).count
    @marketing_2_count = PriorReservation.where(marketing_2_email_sent_at: nil).count
    flash.now[:alert] = "Emailing is disabled. Enable email notifications in Settings to send marketing emails." unless helpers.setting.is_emailing_enabled?
  end

  def send_marketing_email_1
    if Setting.instance.is_emailing_enabled?
      SendMarketingEmail1Job.perform_later
      count_to_be_sent = PriorReservation.where(marketing_1_email_sent_at: nil).count
      redirect_to admin_marketing_index_path, notice: "#{ helpers.setting.email_batch_quantity} out of #{count_to_be_sent} marketing #1 emails queued to be sent."
    else
      redirect_to admin_marketing_index_path, alert: "Emailing is disabled. Enable email notifications in Settings to send marketing emails."
    end
  end

  def send_marketing_email_2
    if Setting.instance.is_emailing_enabled?
      SendMarketingEmail2Job.perform_later
      count_to_be_sent = PriorReservation.where(marketing_2_email_sent_at: nil).count
      redirect_to admin_marketing_index_path, notice: "#{ helpers.setting.email_batch_quantity} out of #{count_to_be_sent} marketing #2 emails queued to be sent."
    else
      redirect_to admin_marketing_index_path, alert: "Emailing is disabled. Enable emailing in Settings to send marketing emails."
    end
  end
end
