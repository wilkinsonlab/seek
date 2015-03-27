class OpenbisSample < ActiveRecord::Base
  attr_accessible :contributor_id, :contributor_type, :description, :last_sync, :last_used_at, :perm_id, :policy_id, :title, :uuid, :openbis_json

  delegate :modification_date,:registration_date,:code,:properties,:identifier, :to=>:internal_sample

  has_and_belongs_to_many :data_files

  acts_as_asset

  searchable(:auto_index=>false) do
    text :perm_id,:code,:identifier

    text :metadata do
      properties.keys.collect do |key|
        [key,properties[key]]
      end.flatten
    end
  end if Seek::Config.solr_enabled

  belongs_to :assay

  def self.load_from_openbis_sample sample
    entity = OpenbisSample.new
    entity.openbis_json = sample.json.to_json
    entity.perm_id = sample.perm_id
    entity.title = sample.code
    entity.description = sample.comment
    entity.last_sync = Time.now

    entity
  end

  def default_policy
    Policy.public_policy
  end

  def assays
    [assay]
  end

  def default_contributor
    User.current_user.person
  end

  def internal_sample
    @internal ||= Seek::Openbis::Zample.new(perm_id)
  end
end
