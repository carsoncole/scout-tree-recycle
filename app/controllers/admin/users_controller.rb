class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :edit, :update, :destroy ]
  before_action :require_admin_access, except: [ :index ]

  def index
    @pagy, @users = pagy(User.all.order(created_at: :desc))
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to admin_users_path, notice: "User was successfully created."
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

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :time_zone)
  end

  def require_admin_access
    unless Current.user.admin?
      redirect_to admin_users_path, alert: "You are not authorized to manage users."
    end
  end
end
