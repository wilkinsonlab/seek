class AddOpenbisFieldsToDataFileVersion < ActiveRecord::Migration
  def change
    add_column :data_file_versions, :perm_id, :string
    add_column :data_file_versions, :openbis_json, :string
    add_column :data_file_versions, :last_sync, :datetime
  end
end
