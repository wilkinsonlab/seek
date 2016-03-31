class OpenbisSample < ActiveRecord::Base
  attr_accessible :contributor_id, :contributor_type, :description, :last_sync, :last_used_at, :perm_id, :policy_id, :title, :uuid, :openbis_json

  delegate :modification_date,:registration_date,:code,:properties,:identifier, :to=>:internal_sample

  has_and_belongs_to_many :data_files

  scope :default_order, order('title')

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
    entity.update_from_openbis_sample(sample)

    entity
  end

  def openbis_refresh
    zample=Seek::Openbis::Zample.new(perm_id)
    Rails.cache.delete(zample.cache_key(perm_id))
    self.update_from_openbis_sample(zample)
    self.save!
  end

  def update_from_openbis_sample(sample)
    self.openbis_json = sample.json.to_json
    self.perm_id = sample.perm_id
    self.title = sample.code
    self.description = sample.comment
    self.last_sync = Time.now
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
    @internal ||= Seek::Openbis::Zample.new.populate_from_json(JSON.parse(openbis_json))
  end
end
