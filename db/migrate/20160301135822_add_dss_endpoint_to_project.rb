class AddDssEndpointToProject < ActiveRecord::Migration
  def change
    add_column :projects,:openbis_dss_endpoint, :string
  end
end
