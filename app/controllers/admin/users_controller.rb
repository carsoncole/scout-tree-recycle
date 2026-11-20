class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :edit, :update, :destroy ]
  before_action :require_admin_access, except: [ :index ]
  before_action :require_configured_email, only: [ :create ]

  def index
    @pagy, @users = pagy(User.all.order(created_at: :desc))
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new_with_temporary_password(create_params)

    if @user.save
      UsersMailer.account_created(@user).deliver_later
      redirect_to admin_users_path, notice: "User was created. An account setup email was sent to #{@user.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.admin? && User.where(role: "admin").count <= 1
      redirect_to admin_users_path, alert: "Cannot delete the last admin user."
    else
      @user.destroy
      redirect_to admin_users_path, notice: "User was successfully deleted."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def create_params
    params.require(:user).permit(:email, :role)
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role)
  end

  def require_admin_access
    unless Current.user.admin?
      redirect_to admin_users_path, alert: "You are not authorized to manage users."
    end
  end

  # The emailed link is the only way a new user can create their password, so
  # creation is blocked until email settings are complete. The blocked attempt
  # is recorded so the reason is visible in the system log.
  def require_configured_email
    alert = Setting.instance&.email_configuration_alert(purpose: "emailing the account setup link")
    return if alert.blank?

    Log.create(
      log_type: "email",
      severity: "warning",
      message: "New user creation blocked: #{alert}",
      context: { attempted_email: params.dig(:user, :email).presence }
    )

    redirect_to new_admin_user_path, alert: alert
  end
end
