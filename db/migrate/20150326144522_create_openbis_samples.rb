class CreateOpenbisSamples < ActiveRecord::Migration
  def change
    create_table :openbis_samples do |t|
      t.string :title
      t.string :description
      t.string :perm_id
      t.datetime :last_sync
      t.integer :policy_id
      t.string :contributor_type
      t.integer :contributor_id
      t.string :uuid
      t.datetime :last_used_at
      t.string :openbis_json
      t.integer :assay_id
      t.string :first_letter

      t.timestamps
    end
  end
end
