class AddOpenBisToProject < ActiveRecord::Migration

  def change
    add_column :projects,:openbis_username, :string
    add_column :projects,:openbis_password, :string
    add_column :projects,:openbis_endpoint, :string
  end

end
