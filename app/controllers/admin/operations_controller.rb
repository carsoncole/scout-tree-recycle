class Admin::OperationsController < Admin::BaseController
  # migrate reservations to contacts and remove old contacts
  def post_event_cleanup
    if Current.user.admin?
      Reservation.migrate_reservations! # migrate 'active' reservations to contacts
      Contact.remove_old_contacts!
      Contact.clear_email_flags! # reset email 1 and 2 sent at attributes
      Log.create(message: "Reservations migration completed successfully.", context: { user: Current.user.email })
      redirect_to admin_settings_path, notice: "Reservations migration completed successfully."
    else
      redirect_to admin_settings_path, alert: "You are not authorized to perform this operation."
    end
  end
end
