class DataMailer < AdminMailer
  # Delivers the zip backup as an attachment to any address.
  def backup_email(recipient, datasets: Backup.dataset_keys)
    @setting = Setting.instance
    @backup = Backup.new(datasets: datasets, setting: @setting)
    @dataset_labels = @backup.datasets.map(&:label)
    organization_name = @setting&.organization_name.presence || "Tree Recycle"

    attachments[@backup.filename] = { mime_type: "application/zip", content: @backup.to_zip }

    mail to: recipient, subject: "Data backup from #{organization_name}"
  end
end
