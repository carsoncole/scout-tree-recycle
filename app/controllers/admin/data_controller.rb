class Admin::DataController < Admin::BaseController
  def show
  end

  def import
    file = params[:file]
    unless file.respond_to?(:read)
      redirect_to admin_data_path, alert: "Please choose a CSV file to import."
      return
    end

    csv = file.read
    result = ReservationCsvImport.new(
      csv: csv,
      filename: file.original_filename.to_s,
      mapping: params[:mapping],
      user: Current.user
    ).perform

    if result.error.present?
      redirect_to admin_data_path, alert: result.error
    elsif result.failed.positive?
      redirect_to admin_data_path, alert: "Imported #{result.imported} reservation(s). Skipped #{result.skipped} duplicate(s). #{result.failed} row(s) failed. Check the System Logs for details."
    elsif result.skipped.positive?
      redirect_to admin_data_path, notice: "Imported #{result.imported} reservation(s). Skipped #{result.skipped} duplicate email(s)."
    else
      redirect_to admin_data_path, notice: "Imported #{result.imported} reservation(s) successfully."
    end
  end

  def export
    send_data Reservation.to_csv,
      filename: "reservations-#{Time.current.strftime("%Y%m%d-%H%M%S")}.csv",
      type: "text/csv; charset=utf-8",
      disposition: "attachment"
  end
end
