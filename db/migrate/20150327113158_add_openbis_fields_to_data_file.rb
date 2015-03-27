class AddOpenbisFieldsToDataFile < ActiveRecord::Migration
  def change
    add_column :data_files, :perm_id, :string
    add_column :data_files, :openbis_json, :string
    add_column :data_files, :last_sync, :datetime
  end
end
