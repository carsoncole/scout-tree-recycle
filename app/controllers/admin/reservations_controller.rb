class Admin::ReservationsController < Admin::BaseController
  before_action :set_reservation, only: [ :show, :edit, :update, :destroy, :geocode, :verify_address, :route, :assign_route, :resend_email, :send_pickup_reminder_email ]

  def index
    @reservations = Reservation.for_admin_index(
      sort: params[:sort],
      direction: params[:direction],
      status: params[:status],
      query: params[:q],
      address_check: params[:address_check]
    )
    @pagy, @reservations = pagy(@reservations)
    @pickup_reminder_count = Reservation.pickup_reminder_pending.count
    @pickup_reminder_template = ReservationEmailTemplate.find_by(name: "pickup_reminder_email")
    setting = Setting.instance
    @emailing_enabled = setting.is_emailing_enabled?
    @email_batch_quantity = setting.email_batch_quantity
    @pickup_reminder_batch_size = setting.email_batch_size(@pickup_reminder_count)
    flash.now[:alert] = "Reservations are CLOSED." unless Reservation.open?
  end

  def send_pickup_reminder_emails
    setting = Setting.instance
    count = Reservation.pickup_reminder_pending.count

    if !setting.is_emailing_enabled?
      redirect_to admin_reservations_path, alert: "Emailing is disabled. Enable it in Settings before sending pickup reminder emails."
    elsif (message = setting.email_configuration_alert(purpose: "sending pickup reminder emails"))
      redirect_to admin_reservations_path, alert: message
    elsif ReservationEmailTemplate.published.find_by(name: "pickup_reminder_email").nil?
      redirect_to admin_reservations_path, alert: "Pickup reminder email is not published. Edit the template and publish it before sending."
    elsif count.zero?
      redirect_to admin_reservations_path, alert: "No reservations are eligible for a pickup reminder email."
    else
      SendPickupReminderEmailsJob.perform_later
      redirect_to admin_reservations_path, notice: "#{setting.email_batch_size(count)} of #{count} pickup reminder emails queued to be sent."
    end
  end

  def send_pickup_reminder_email
    setting = Setting.instance

    if !setting.is_emailing_enabled?
      redirect_to admin_reservation_path(@reservation), alert: "Emailing is disabled. Enable it in Settings before sending emails."
    elsif ReservationEmailTemplate.published.find_by(name: "pickup_reminder_email").nil?
      redirect_to admin_reservation_path(@reservation), alert: "Pickup reminder email is not published. Edit the template and publish it before sending."
    elsif !@reservation.pickup_reminder_eligible?
      redirect_to admin_reservation_path(@reservation), alert: "This reservation is not eligible for a pickup reminder email."
    elsif @reservation.pickup_reminder_email_sent_at.present?
      redirect_to admin_reservation_path(@reservation), alert: "Pickup reminder email was already sent to #{@reservation.email}."
    else
      ReservationsMailer.with(reservation_id: @reservation.id).pickup_reminder_email.deliver_later
      redirect_to admin_reservation_path(@reservation), notice: "Pickup reminder email was queued for delivery to #{@reservation.email}."
    end
  end

  def show
    @reservation_logs = @reservation.logs.recent_first.limit(10)
    @has_more_reservation_logs = @reservation.logs.count > @reservation_logs.length
    @donations = @reservation.donations.order(created_at: :desc)
  end

  def edit
  end

  def update
    if @reservation.update(reservation_params)
      redirect_to admin_reservation_path(@reservation), notice: "Reservation was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reservation.destroy
    redirect_to admin_reservations_path, notice: "Reservation was successfully deleted."
  end

  def geocode
    unless Setting.instance.is_routing_enabled
      redirect_back fallback_location: admin_reservation_path(@reservation), alert: "Routing is disabled"
      return
    end

    if @reservation.full_geocode!
      @reservation.save
      redirect_to admin_reservation_path(@reservation), notice: "Reservation was successfully geocoded."
    else
      redirect_to admin_reservation_path(@reservation), alert: "Geocoding was not successful."
    end
  end

  def verify_address
    unless Setting.instance.address_verification_available?
      redirect_to admin_reservation_path(@reservation),
                  alert: "Address verification requires automatic routing and Places v2."
      return
    end

    if @reservation.verify_address!
      redirect_to admin_reservation_path(@reservation), notice: "Address verified for the pickup area."
    else
      redirect_to admin_reservation_path(@reservation),
                  alert: "Address could not be verified for the pickup area. It will need manual routing."
    end
  end

  def route
    unless Setting.instance.is_routing_enabled
      redirect_to admin_reservation_path(@reservation), alert: "Routing is disabled"
      return
    end

    @reservation.route_reservation!
    redirect_to admin_reservation_path(@reservation), notice: "Reservation was queued for routing."
  end

  def assign_route
    if @reservation.update(route_params)
      redirect_to admin_reservation_path(@reservation), notice: "Reservation route was successfully updated."
    else
      redirect_to admin_reservation_path(@reservation), alert: "Reservation route could not be updated."
    end
  end

  def resend_email
    email_config = Reservation::EMAIL_KINDS[params[:kind].to_s]

    unless email_config
      redirect_to admin_reservation_path(@reservation), alert: "Unknown email type."
      return
    end

    if params[:kind].to_s == "donation_receipt" && !@reservation.donations.exists?
      redirect_to admin_reservation_path(@reservation), alert: "This reservation does not have a donation."
      return
    end

    unless Setting.instance.is_emailing_enabled?
      redirect_to admin_reservation_path(@reservation), alert: "Emailing is disabled. Enable it in Settings before sending emails."
      return
    end

    @reservation.resend_email!(params[:kind])
    redirect_to admin_reservation_path(@reservation), notice: "#{email_config[:label]} was queued for delivery to #{@reservation.email}."
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(
      :name, :email, :mobile, :street, :city, :state, :country,
      :route_id, :status, :pickup_notes, :latitude, :longitude,
      :is_missing_tree_notifications_enabled
    )
  end

  def route_params
    params.require(:reservation).permit(:route_id)
  end
end
