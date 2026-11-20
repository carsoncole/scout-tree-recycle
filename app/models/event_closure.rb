# Closes the current event: copies eligible reservations into contacts,
# deletes every reservation, drops contacts past retention, and clears
# marketing send dates so the next event can start.
class EventClosure
  CONFIRMATION_WORD = "CLOSE"

  def self.confirmed?(word)
    word.to_s.strip.casecmp?(CONFIRMATION_WORD)
  end

  def perform!
    Reservation.migrate_reservations!
    Contact.remove_old_contacts!
    Contact.clear_email_flags!
  end

  def retention_months
    Setting.instance&.contact_retention_months.presence || Setting::DEFAULT_RETENTION_MONTHS
  end

  def copied_count
    Reservation.migratable.count
  end

  def discarded_count
    Reservation.where.not(status: Reservation::MIGRATABLE_STATUSES).count
  end

  def reservation_count
    Reservation.count
  end

  def contacts_replaced_count
    Contact.where(email: Reservation.migratable.select(:email)).count
  end

  def contacts_removed_count
    Contact.where("created_at < ?", retention_months.months.ago)
      .where.not(email: Reservation.migratable.select(:email))
      .count
  end

  def copied_status_labels
    Reservation::MIGRATABLE_STATUSES.map(&:humanize)
  end

  def discarded_status_labels
    (Reservation.statuses.keys - Reservation::MIGRATABLE_STATUSES).map(&:humanize)
  end
end
