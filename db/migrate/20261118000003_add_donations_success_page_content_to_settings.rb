class AddDonationsSuccessPageContentToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :donations_success_page_content, :text
  end
end
