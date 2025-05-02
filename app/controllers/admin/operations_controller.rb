class Admin::OperationsController < Admin::BaseController
  # migrate reservations to prior reservations and remove old prior reservations
  def post_event_cleanup
    if Current.user.admin?
      Reservation.migrate_reservations! # migrate 'active' reservations to prior reservations
      PriorReservation.remove_old_prior_reservations! # remove old prior reservations older than MINIMUM_MONTHS_BEFORE_PRIOR_RESERVATION_REMOVAL
      PriorReservation.clear_email_flags! # reset email 1 and 2 sent at attributes
      Log.create(message: "Reservations migration completed successfully.", context: { user: Current.user.email })
      redirect_to admin_settings_path, notice: "Reservations migration completed successfully."
    else
      redirect_to admin_settings_path, alert: "You are not authorized to perform this operation."
    end
  end
end
