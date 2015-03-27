class CreateDataFilesOpenbisSamples < ActiveRecord::Migration
  def change
    create_table :data_files_openbis_samples,:id => false do |t|
      t.integer :data_file_id
      t.integer :openbis_sample_id
    end
  end

end
