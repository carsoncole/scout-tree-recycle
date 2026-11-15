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
    result = ContactCsvImport.new(
      csv: csv,
      filename: file.original_filename.to_s,
      mapping: params[:mapping],
      user: Current.user
    ).perform

    if result.error.present?
      redirect_to admin_data_path, alert: result.error
    elsif result.failed.positive?
      all_row_errors = Array(result.row_errors || result.errors || result.failed_rows || result.failures)
      display_errors = all_row_errors.first(5).map do |row_error|
        row_number = row_error[:row] || row_error["row"]
        messages = Array(row_error[:errors] || row_error["errors"]).map { |message| message.to_s.truncate(80) }
        { row: row_number, errors: messages }
      end
      row_error_details = display_errors.map do |row_error|
        "Row #{row_error[:row]}: #{row_error[:errors].join(", ")}"
      end.join("; ")
      row_error_details += "; and #{all_row_errors.size - display_errors.size} more" if all_row_errors.size > display_errors.size
      alert = "Imported #{result.imported} contact(s). Skipped #{result.skipped} duplicate(s). #{result.failed} row(s) failed."
      alert += " #{row_error_details}." if row_error_details.present?
      alert += " Check the System Logs for details."
      flash[:import_errors] = display_errors if display_errors.any?
      redirect_to admin_data_path, alert: alert
    elsif result.skipped.positive?
      redirect_to admin_data_path, notice: "Imported #{result.imported} contact(s). Skipped #{result.skipped} duplicate email(s)."
    else
      redirect_to admin_data_path, notice: "Imported #{result.imported} contact(s) successfully."
    end
  end

  def export
    send_data Reservation.to_csv,
      filename: "reservations-#{Time.current.strftime("%Y%m%d-%H%M%S")}.csv",
      type: "text/csv; charset=utf-8",
      disposition: "attachment"
  end
end
