class UpdateJsonFields < ActiveRecord::Migration
  def up
    change_column :data_files, :openbis_json, :text, :limit=>1000000
    change_column :openbis_samples, :openbis_json, :text, :limit=>1000000
    change_column :openbis_samples, :description, :text
  end

  def down
    change_column :data_files, :openbis_json, :string
    change_column :openbis_samples, :openbis_json, :string
    change_column :openbis_samples, :description, :string
  end
end
