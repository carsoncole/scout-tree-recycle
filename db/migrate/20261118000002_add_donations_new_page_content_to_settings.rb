class AddDonationsNewPageContentToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :donations_new_page_content, :text
  end
end
