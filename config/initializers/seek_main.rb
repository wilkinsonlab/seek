#DO NOT EDIT THIS FILE.
#TO MODIFY THE DEFAULT SETTINGS, COPY seek_local.rb.pre to seek_local.rb AND EDIT THAT FILE INSTEAD

require 'object'
require 'authorization'
require 'save_without_timestamping'
require 'asset'
require 'calendar_date_select'
require 'object'
require 'active_record_extensions'
require 'acts_as_taggable_extensions'
require 'acts_as_isa'
require 'acts_as_yellow_pages'
require 'seek/acts_as_uniquely_identifiable'
require 'acts_as_favouritable'
require 'acts_as_asset'
require 'send_subscriptions_when_activity_logged'
require 'modporter_extensions'
require "attachment_fu_extension"
require 'seek/taggable'
require "bio"
require 'assets_common_extension'
require 'sunspot_rails'
require 'cancan'
require 'strategic_eager_loading'


GLOBAL_PASSPHRASE="ohx0ipuk2baiXah" unless defined? GLOBAL_PASSPHRASE

ASSET_ORDER                = ['Person', 'Project', 'Institution', 'Investigation', 'Study', 'Assay', 'Sample','Specimen','DataFile', 'Model', 'Sop', 'Publication', 'Presentation','SavedSearch', 'Organism', 'Event']

PORTER_SECRET = "" unless defined? PORTER_SECRET

Seek::Config.propagate_all

#these inflections are put here, because the config variables are just loaded after the propagation
ActiveSupport::Inflector.inflections do |inflect|
  inflect.human 'Specimen', Seek::Config.sample_parent_term.capitalize  unless Seek::Config.sample_parent_term.blank?
  inflect.human 'specimen', Seek::Config.sample_parent_term.capitalize  unless Seek::Config.sample_parent_term.blank?
end

Annotations::Config.attribute_names_to_allow_duplicates.concat(["tag"])
Annotations::Config.versioning_enabled = false

CELL_CULTURE_OR_SPECIMEN = Seek::Config.is_virtualliver ? 'specimen' : 'cell culture'
ENV['LANG'] = 'en_US.UTF-8'


if ActiveRecord::Base.connection.table_exists? 'delayed_jobs'
  SendPeriodicEmailsJob.create_initial_jobs
end

#disable xml parameter parsing to avoid rail vulnarability
#ActionController::Base.param_parsers.delete(Mime::XML) 

#can not disable xml parameter parsing, it is used in email upload tool authorization
#so disable the conversions
ActiveSupport::CoreExtensions::Hash::Conversions::XML_PARSING.delete('symbol') 
ActiveSupport::CoreExtensions::Hash::Conversions::XML_PARSING.delete('yaml') 

#reduce entity_expansion_limit to limit entity explosion attacks, the default 
#value is 10000
REXML::Document.entity_expansion_limit = 1000

