class AddExperimentIdToStudy < ActiveRecord::Migration
  def change
    add_column :studies, :openbis_experiment_id, :string
  end
end
