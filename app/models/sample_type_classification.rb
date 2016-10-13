# Represents the classification of a sample-type according to a term from the JERM ontology
class SampleTypeClassification < ActiveRecord::Base
  validates :title, :ontology_term, presence: true
  validates :title, uniqueness: true

  validates :ontology_term, format: {
    with: URI.regexp, message: 'Must be a URI'
  }

  has_many :sample_types
end
