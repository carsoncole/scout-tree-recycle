module Admin::SmsHelper
    def recipient
      reservation&.name
    end

    def reservation_link
      link_to reservation.name, admin_reservation_path(reservation.id) if reservation.present?
    end

    def reservation_link_if_present
      reservation_link || sms.phone
    end
end
