class AddSuggestedDonationToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :suggested_donation, :integer, default: 25
  end
end
