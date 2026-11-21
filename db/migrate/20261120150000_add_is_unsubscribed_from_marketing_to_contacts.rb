class AddIsUnsubscribedFromMarketingToContacts < ActiveRecord::Migration[8.1]
  def change
    add_column :contacts, :is_unsubscribed_from_marketing, :boolean, default: false, null: false
  end
end
