
class Admin::PointsController < Admin::BaseController
  before_action :set_route
  before_action :set_point, only: [ :edit, :update, :destroy ]

  def edit
  end

  def create
    @point = @route.points.build(point_params)

    if @point.save
      redirect_to edit_admin_route_path(@route), notice: "Point was successfully added."
    else
      redirect_to edit_admin_route_path(@route), alert: "Failed to add point: #{@point.errors.full_messages.join(', ')}"
    end
  end

  def update
    if @point.update(point_params)
      redirect_to edit_admin_route_path(@route), notice: "Point was successfully updated."
    else
      redirect_to edit_admin_route_path(@route), alert: "Failed to update point: #{@point.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @point.destroy!
    redirect_to edit_admin_route_path(@route), notice: "Point was successfully removed."
  end

  private

  def set_route
    @route = Route.find(params[:route_id])
  end

  def set_point
    @point = @route.points.find(params[:id])
  end

  def point_params
    params.require(:point).permit(:latitude, :longitude, :order)
  end
end
