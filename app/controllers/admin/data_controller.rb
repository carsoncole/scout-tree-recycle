class Admin::DataController < Admin::BaseController
  before_action :require_admin_access, except: [ :show ]

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
    if csv.bytesize > ContactCsvImport::MAX_FILE_SIZE
      redirect_to admin_data_path, alert: "CSV file is too large (maximum 5 MB)."
      return
    end

    # Uploaded file contents read as binary (ASCII-8BIT). Job arguments are
    # stored as JSON, which cannot encode high bytes in a binary string, so
    # normalize to valid UTF-8 here (ContactCsvImport scrubs it again when
    # parsing).
    csv = csv.force_encoding("UTF-8").scrub

    # Large imports run long enough to time out the request, so the work is
    # performed by a background job. The outcome is recorded in the System
    # Logs with the "job" log type.
    ContactCsvImportJob.perform_later(
      csv: csv,
      filename: file.original_filename.to_s,
      mapping: Array(params[:mapping]).map(&:to_s),
      user: Current.user
    )
    redirect_to admin_data_path, notice: "Contact import queued. Check the System Logs for results."
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
    Log.create(
      log_type: "system",
      message: "Reservations CSV export emailed to #{recipient}.",
      severity: "info",
      handled: true,
      skip_notification: true,
      context: { recipient: recipient, user: Current.user&.email }
    )
    redirect_to admin_data_path, notice: "Reservations CSV emailed to #{recipient}."
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning, context: { email: recipient })
    redirect_to admin_data_path, alert: "The export email could not be sent: #{e.message}"
  end

  private

  def require_admin_access
    unless Current.user.admin?
      redirect_to admin_data_path, alert: "You are not authorized to perform this data action."
    end
  end

  def schedule_params
    params.require(:setting).permit(
      :is_reservations_export_schedule_enabled,
      :reservations_export_email,
      :reservations_export_time
    )
  end
end
