class Admin::DataController < Admin::BaseController
  def show
    @setting = Setting.instance
    @database_overview = DatabaseOverview.new
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

  def schedule
    setting = Setting.instance
    return redirect_to admin_data_path, alert: "Complete the initial settings before scheduling exports." if setting.nil?

    if setting.update(schedule_params)
      redirect_to admin_data_path, notice: "Daily reservations export schedule saved."
    else
      redirect_to admin_data_path, alert: setting.errors.full_messages.to_sentence
    end
  end

  def email_export
    recipient = params.dig(:setting, :reservations_export_email).to_s.strip

    if recipient.blank? || !recipient.match?(URI::MailTo::EMAIL_REGEXP)
      return redirect_to admin_data_path, alert: "Enter a valid email address to receive the export."
    end

    if (message = Setting.instance&.email_configuration_alert(purpose: "emailing the export"))
      return redirect_to admin_data_path, alert: message
    end

    DataMailer.reservations_export_email(recipient).deliver_now
    redirect_to admin_data_path, notice: "Reservations CSV emailed to #{recipient}."
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning, context: { email: recipient })
    redirect_to admin_data_path, alert: "The export email could not be sent: #{e.message}"
  end

  private

  def schedule_params
    params.require(:setting).permit(
      :is_reservations_export_schedule_enabled,
      :reservations_export_email,
      :reservations_export_time
    )
  end
end
