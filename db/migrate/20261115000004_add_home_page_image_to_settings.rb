class AddHomePageImageToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :home_page_image, :string, default: "fleur-de-lis-2024-logo-4c-bc.png", null: false
  end
end
