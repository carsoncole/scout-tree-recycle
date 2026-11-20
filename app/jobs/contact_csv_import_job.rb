# Imports contacts from an uploaded CSV in the background so large files do
# not time out the browser request. Every run is recorded in the System Logs
# with the "job" log type; rows that cannot be imported are also recorded
# there as individual error entries by ContactCsvImport.
class ContactCsvImportJob < ApplicationJob
  queue_as :default

  def perform(csv:, filename:, mapping:, user: nil)
    result = ContactCsvImport.new(csv: csv, filename: filename, mapping: mapping, user: user).perform

    Log.create(
      log_type: "job",
      message: log_message(result),
      error_type: "ContactCsvImportJob",
      severity: result.error.present? || result.failed.positive? ? "warning" : "info",
      handled: true,
      skip_notification: true,
      context: {
        user: user&.email,
        filename: filename,
        imported: result.imported,
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
      "Contact import job failed: #{result.error}"
    else
      "Contact import job completed: imported #{result.imported}, skipped #{result.skipped}, failed #{result.failed}."
    end
  end
end
