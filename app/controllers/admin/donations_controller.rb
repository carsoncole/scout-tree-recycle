class Admin::DonationsController < Admin::BaseController
  def index
    @donations = Donation.includes(:reservation).order(created_at: :desc)
    flash.now[:alert] = "Online Donations are disabled. Enable Online Donations in Settings to accept online payments." unless helpers.setting.is_donations_enabled?
  end

  def show
    @donation = Donation.find(params[:id])
  end

  def destroy
    @donation = Donation.find(params[:id])
    @donation.destroy
    redirect_to admin_donations_path, notice: "Donation was successfully deleted."
  end
end

