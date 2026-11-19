class RemoveLocationServiceDefaultsFromSettings < ActiveRecord::Migration[8.1]
  # AWS location settings must start blank and be fully user configurable.
  # Earlier migrations added aws_region and aws_location_index_name with
  # column defaults, which also backfilled existing rows. Remove the column
  # defaults and clear any stored values that came from them.
  def up
    change_column_default :settings, :aws_region, nil
    change_column_default :settings, :aws_location_index_name, nil

    execute "UPDATE settings SET aws_region = NULL WHERE aws_region = 'us-west-2'"
    execute "UPDATE settings SET aws_location_index_name = NULL WHERE aws_location_index_name = 'tree_recycle'"
  end

  def down
    change_column_default :settings, :aws_region, "us-west-2"
    change_column_default :settings, :aws_location_index_name, "tree_recycle"
  end
end
