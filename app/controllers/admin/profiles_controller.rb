class Admin::ProfilesController < Admin::BaseController
  before_action :set_user

  def show
    @email_configured = Setting.instance&.email_configured?
  end

  def update
    if @user.update_profile(profile_params)
      sign_out_other_sessions if @user.password_digest_previously_changed?
      redirect_to admin_profile_path, notice: "Profile was successfully updated."
    else
      @email_configured = Setting.instance&.email_configured?
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def profile_params
    params.require(:user).permit(:email, :password, :password_confirmation, :password_challenge)
  end

  def sign_out_other_sessions
    return unless Current.session

    @user.sessions.where.not(id: Current.session.id).destroy_all
  end
end
