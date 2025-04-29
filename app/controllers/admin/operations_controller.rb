class Admin::OperationsController < Admin::BaseController
  # migrate reservations to prior reservations and remove old prior reservations
  def migrate_reservations
    Reservation.migrate_reservations!
    PriorReservation.remove_old_prior_reservations!
    redirect_to admin_settings_path, notice: "Reservations migration completed successfully."
  end
end
