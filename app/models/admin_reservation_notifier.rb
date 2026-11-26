# Broadcasts transient new-reservation notifications to signed-in admins.
# The notifications are not persisted; they only reach admin pages that are
# open when the delayed notification job runs.
class AdminReservationNotifier
  STREAM = "admin_reservation_notifications".freeze
  CONTAINER_ID = "admin-notifications".freeze
  PARTIAL = "admin/shared/reservation_notification".freeze

  def self.created(reservation)
    broadcast(:prepend, reservation, CONTAINER_ID)
  end

  def self.dom_id(reservation)
    "reservation-notification-#{reservation.id}"
  end

  def self.broadcast(action, reservation, target)
    Turbo::StreamsChannel.public_send(
      "broadcast_#{action}_to",
      STREAM,
      target: target,
      partial: PARTIAL,
      locals: { reservation: reservation }
    )
  rescue StandardError => e
    Rails.logger.error("Admin reservation notification broadcast failed: #{e.class}: #{e.message}")
  end
  private_class_method :broadcast
end
