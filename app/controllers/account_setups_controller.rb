class AccountSetupsController < ApplicationController
  include Authentication
  allow_unauthenticated_access only: %i[ edit update ]

  before_action :set_user_by_token, only: %i[ edit update ]

  def edit
  end

  def update
    if @user.set_password(params.permit(:password, :password_confirmation))
      start_new_session_for(@user)
      redirect_to admin_root_url, notice: "Your password has been set."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_account_setup_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    redirect_to new_admin_session_path, alert: "This account setup link is invalid or has expired."
  end
end
