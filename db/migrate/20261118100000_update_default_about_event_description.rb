class UpdateDefaultAboutEventDescription < ActiveRecord::Migration[8.1]
  OLD_DEFAULT = "Tree Recycle is a community event where we collect trees and recycle them into mulch. This is our primary fundraiser for the year and all proceeds go to the Troop."
  NEW_DEFAULT = "This is a community event where we collect trees and recycle them into mulch. It's an important fundraiser for our organization, and the proceeds go towards supporting us."

  def up
    execute "UPDATE settings SET about_event_description = '#{NEW_DEFAULT.gsub("'", "''")}' WHERE about_event_description = '#{OLD_DEFAULT.gsub("'", "''")}'"
  end

  def down
    execute "UPDATE settings SET about_event_description = '#{OLD_DEFAULT.gsub("'", "''")}' WHERE about_event_description = '#{NEW_DEFAULT.gsub("'", "''")}'"
  end
end
