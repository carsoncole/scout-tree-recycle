class AddUnsubscribedAtToContacts < ActiveRecord::Migration[8.1]
  def change
    add_column :contacts, :unsubscribed_at, :datetime
  end
end
