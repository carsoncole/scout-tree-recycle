class Admin::OperationsController < Admin::BaseController
  def migrate_reservations
    Reservation.migrate_reservations!
    redirect_to admin_settings_path, notice: "Reservations migration completed successfully."
  end
end
