class RemoveLocationServiceDefaultsFromSettings < ActiveRecord::Migration[8.1]
  # Region and place index have no column default. An admin enters both.
  # The examples stay in the form as placeholders only.
  def up
    change_column_default :settings, :aws_region, nil
    change_column_default :settings, :aws_location_index_name, nil
  end

  def down
    change_column_default :settings, :aws_region, "us-west-2"
    change_column_default :settings, :aws_location_index_name, "tree_recycle"
  end
end
