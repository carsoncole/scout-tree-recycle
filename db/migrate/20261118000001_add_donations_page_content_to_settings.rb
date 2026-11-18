class AddDonationsPageContentToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :donations_page_content, :text
    add_column :settings, :donations_page_how_to_donate, :text
  end
end
