class Admin::ThanksController < Admin::BaseController
  before_action :set_thank, only: [ :edit, :update, :destroy ]
  before_action :require_admin_access

  def index
    @thanks = Thank.recent
  end

  def new
    @thank = Thank.new
  end

  def create
    @thank = Thank.new(thank_params)

    if @thank.save
      redirect_to admin_thanks_path, notice: "Thank was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @thank.update(thank_params)
      redirect_to admin_thanks_path, notice: "Thank was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @thank.destroy
    redirect_to admin_thanks_path, notice: "Thank was successfully deleted."
  end

  private

  def set_thank
    @thank = Thank.find(params[:id])
  end

  def thank_params
    params.require(:thank).permit(:content, :image_upload)
  end

  def require_admin_access
    unless Current.user.admin?
      redirect_to admin_settings_path, alert: "You are not authorized to manage thanks."
    end
  end
end
