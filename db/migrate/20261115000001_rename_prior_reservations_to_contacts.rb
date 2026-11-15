class RenamePriorReservationsToContacts < ActiveRecord::Migration[8.1]
  def up
    rename_table :prior_reservations, :contacts

    if index_name_exists?(:contacts, "index_prior_reservations_on_email")
      rename_index :contacts, "index_prior_reservations_on_email", "index_contacts_on_email"
    end

    if index_name_exists?(:contacts, "index_prior_reserations_on_marketing_1_email_sent_at")
      rename_index :contacts, "index_prior_reserations_on_marketing_1_email_sent_at", "index_contacts_on_marketing_1_email_sent_at"
    end

    rename_column :settings, :prior_reservation_retention_months, :contact_retention_months
  end

  def down
    rename_column :settings, :contact_retention_months, :prior_reservation_retention_months

    if index_name_exists?(:contacts, "index_contacts_on_email")
      rename_index :contacts, "index_contacts_on_email", "index_prior_reservations_on_email"
    end

    if index_name_exists?(:contacts, "index_contacts_on_marketing_1_email_sent_at")
      rename_index :contacts, "index_contacts_on_marketing_1_email_sent_at", "index_prior_reserations_on_marketing_1_email_sent_at"
    end

    rename_table :contacts, :prior_reservations
  end
end
