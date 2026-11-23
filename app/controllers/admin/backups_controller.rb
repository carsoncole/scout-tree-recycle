class Admin::BackupsController < Admin::BaseController
  before_action :require_admin_access

  def create
    backup = build_backup
    return if performed?

    send_data backup.to_zip,
      filename: backup.filename,
      type: "application/zip",
      disposition: "attachment"
  end

  def email
    recipient = params.dig(:setting, :backup_email).to_s.strip

    if recipient.blank? || !recipient.match?(URI::MailTo::EMAIL_REGEXP)
      return redirect_to admin_data_path, alert: "Enter a valid email address to receive the backup."
    end

    if (message = Setting.instance&.email_configuration_alert(purpose: "emailing the backup"))
      return redirect_to admin_data_path, alert: message
    end

    backup = build_backup
    return if performed?

    DataMailer.backup_email(recipient, datasets: backup.dataset_keys).deliver_now
    Log.create(
      log_type: "system",
      message: "Backup emailed to #{recipient}.",
      severity: "info",
      handled: true,
      skip_notification: true,
      context: { recipient: recipient, datasets: backup.dataset_keys, user: Current.user&.email }
    )
    redirect_to admin_data_path, notice: "Backup emailed to #{recipient}."
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :warning, context: { email: recipient })
    redirect_to admin_data_path, alert: "The backup email could not be sent: #{e.message}"
  end

  def schedule
    setting = Setting.instance
    return redirect_to admin_data_path, alert: "Complete the initial settings before scheduling backups." if setting.nil?

    setting.assign_attributes(schedule_params)
    setting.backup_dataset_keys = selected_dataset_keys

    if setting.save
      redirect_to admin_data_path, notice: "Daily backup schedule saved."
    else
      redirect_to admin_data_path, alert: setting.errors.full_messages.to_sentence
    end
  end

  def restore_settings
    file = params[:file]
    unless file.respond_to?(:read)
      return redirect_to admin_data_path, alert: "Please choose a settings JSON file to restore."
    end

    json = file.read
    if json.bytesize > SettingsRestore::MAX_FILE_SIZE
      return redirect_to admin_data_path, alert: "Settings file is too large (maximum 1 MB)."
    end

    json = json.force_encoding("UTF-8").scrub
    result = SettingsRestore.new(json: json, user: Current.user).perform

    if result.success?
      Log.create(
        log_type: "system",
        message: "Settings restored from #{file.original_filename}.",
        severity: "info",
        handled: true,
        skip_notification: true,
        context: { filename: file.original_filename, user: Current.user&.email }
      )
      redirect_to admin_data_path, notice: "Settings restored successfully."
    else
      redirect_to admin_data_path, alert: result.errors.to_sentence
    end
  end

  def restore_reservations
    file = params[:file]
    unless file.respond_to?(:read)
      return redirect_to admin_data_path, alert: "Please choose a reservations CSV file to restore."
    end

    csv = file.read
    if csv.bytesize > ReservationsRestore::MAX_FILE_SIZE
      return redirect_to admin_data_path, alert: "Reservations CSV file is too large (maximum 10 MB)."
    end

    # Uploaded file contents read as binary (ASCII-8BIT). Job arguments are
    # stored as JSON, which cannot encode high bytes in a binary string, so
    # normalize to valid UTF-8 here.
    csv = csv.force_encoding("UTF-8").scrub

    ReservationsRestoreJob.perform_later(
      csv: csv,
      filename: file.original_filename.to_s,
      user: Current.user
    )
    redirect_to admin_data_path, notice: "Reservation restore queued. Check the System Logs for results."
  end

  def restore_contacts
    file = params[:file]
    unless file.respond_to?(:read)
      return redirect_to admin_data_path, alert: "Please choose a contacts CSV file to restore."
    end

    csv = file.read
    if csv.bytesize > ContactsRestore::MAX_FILE_SIZE
      return redirect_to admin_data_path, alert: "Contacts CSV file is too large (maximum 10 MB)."
    end

    # See restore_reservations: keep job arguments valid UTF-8.
    csv = csv.force_encoding("UTF-8").scrub

    ContactsRestoreJob.perform_later(
      csv: csv,
      filename: file.original_filename.to_s,
      user: Current.user
    )
    redirect_to admin_data_path, notice: "Contact restore queued. Check the System Logs for results."
  end

  private

  def require_admin_access
    unless Current.user.admin?
      redirect_to admin_data_path, alert: "You are not authorized to perform this data action."
    end
  end

  def selected_dataset_keys
    Backup.sanitize_dataset_keys(params[:datasets])
  end

  def build_backup
    keys = selected_dataset_keys
    if keys.empty?
      redirect_to admin_data_path, alert: "Choose at least one dataset to back up."
      return
    end

    setting = Setting.instance
    if keys.include?("settings") && setting.nil?
      redirect_to admin_data_path, alert: "Complete the initial settings before backing up settings."
      return
    end

    Backup.new(datasets: keys, setting: setting)
  end

  def schedule_params
    params.require(:setting).permit(:is_backup_schedule_enabled, :backup_email, :backup_time)
  end
end
