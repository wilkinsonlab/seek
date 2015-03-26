class OpenbisSampleAuthLookup < ActiveRecord::Migration
  def change
    create_table :openbis_sample_auth_lookup,:id => false do |t|
      t.integer :user_id
      t.integer :asset_id
      t.boolean :can_view
      t.boolean :can_manage
      t.boolean :can_edit
      t.boolean :can_download
      t.boolean :can_delete,   :default => false
    end
  end

end
