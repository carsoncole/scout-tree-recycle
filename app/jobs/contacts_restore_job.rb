# Restores contacts from an uploaded backup CSV in the background so large
# files do not time out the browser request. Every run is recorded in the
# System Logs with the "job" log type; rows that cannot be restored are also
# recorded there as individual error entries by ContactsRestore.
class ContactsRestoreJob < ApplicationJob
  queue_as :default

  def perform(csv:, filename:, user: nil)
    result = ContactsRestore.new(csv: csv, filename: filename, user: user).perform

    Log.create(
      log_type: "job",
      message: log_message(result),
      error_type: "ContactsRestoreJob",
      severity: result.error.present? || result.failed.positive? ? "warning" : "info",
      handled: true,
      skip_notification: true,
      context: {
        user: user&.email,
        filename: filename,
        created: result.created,
        updated: result.updated,
        skipped: result.skipped,
        failed: result.failed,
        error: result.error,
        row_errors: result.row_errors.first(5)
      }
    )
  end

  private

  def log_message(result)
    if result.error.present?
      "Contact restore job failed: #{result.error}"
    else
      "Contact restore job completed: created #{result.created}, updated #{result.updated}, skipped #{result.skipped}, failed #{result.failed}."
    end
  end
end
