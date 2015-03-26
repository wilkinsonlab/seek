class CreateOpenbisSampleProjects < ActiveRecord::Migration
  def change
    create_table "openbis_samples_projects", :id => false do |t|
      t.integer "project_id"
      t.integer "openbis_sample_id"
    end
  end

end
