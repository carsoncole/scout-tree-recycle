class DataMailer < AdminMailer
  # Delivers the reservations CSV export as an attachment to any address.
  def reservations_export_email(recipient)
    @setting = Setting.instance
    @reservation_count = Reservation.count
    organization_name = @setting&.organization_name.presence || "Tree Recycle"

    filename = "reservations-#{Time.current.strftime("%Y%m%d-%H%M%S")}.csv"
    attachments[filename] = { mime_type: "text/csv", content: Reservation.to_csv }

    mail to: recipient, subject: "Reservations CSV export from #{organization_name}"
  end
end
