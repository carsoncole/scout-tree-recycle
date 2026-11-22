class Admin::DataController < Admin::BaseController
  before_action :require_admin_access, except: [ :show ]

  def show
    @setting = Setting.instance
    @database_overview = DatabaseOverview.new
    @reservations_count = Reservation.count
    @contacts_count = Contact.count
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

  private

  def require_admin_access
    unless Current.user.admin?
      redirect_to admin_data_path, alert: "You are not authorized to perform this data action."
    end
  end
end
