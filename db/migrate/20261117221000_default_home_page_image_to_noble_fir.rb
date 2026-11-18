class DefaultHomePageImageToNobleFir < ActiveRecord::Migration[8.1]
  OLD_DEFAULT = "fleur-de-lis-2024-logo-4c-bc.png"
  NEW_DEFAULT = "tree-4c-bc.png"

  def up
    change_column_default :settings, :home_page_image, NEW_DEFAULT
    execute "UPDATE settings SET home_page_image = '#{NEW_DEFAULT}' WHERE home_page_image = '#{OLD_DEFAULT}'"
  end

  def down
    change_column_default :settings, :home_page_image, OLD_DEFAULT
    execute "UPDATE settings SET home_page_image = '#{OLD_DEFAULT}' WHERE home_page_image = '#{NEW_DEFAULT}'"
  end
end
