class CreateSampleTypeClassification < ActiveRecord::Migration
  def up
    create_table :sample_type_classifications do |t|
      t.string :title
      t.string :ontology_term
    end
    add_column :sample_types, :sample_type_classification_id,:integer
  end

  def down
    drop_table :sample_type_classifications
    remove_column :sample_types, :sample_type_classification_id
  end

end
