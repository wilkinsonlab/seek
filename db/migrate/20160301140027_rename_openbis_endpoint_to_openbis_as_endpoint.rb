class RenameOpenbisEndpointToOpenbisAsEndpoint < ActiveRecord::Migration
  def change
    rename_column :projects,:openbis_endpoint,:openbis_as_endpoint
  end

end
