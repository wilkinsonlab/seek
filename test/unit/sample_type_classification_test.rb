require 'test_helper'

class SampleTypeClassificationTest < ActiveSupport::TestCase

  test 'validation' do
    stc = SampleTypeClassification.new
    refute stc.valid?

    stc.title='fish'
    refute stc.valid?

    stc.ontology_term='http://jerm.org/ontology#term'
    assert stc.valid?

    stc.title=nil
    refute stc.valid?

    stc.title='fish'
    assert stc.valid?

    #ontology term must be valid uri
    stc.ontology_term='bob'
    refute stc.valid?
    stc.ontology_term='bob:111'
    assert stc.valid?

    stc.save!

    #now check the title must be unique
    stc = SampleTypeClassification.new title:'fish',ontology_term:'fred:111'

    refute stc.valid?
    stc.title='frog'

    assert stc.valid?

    #ontology term must also be unique
    stc.ontology_term='bob:111'
    refute stc.valid?


  end

end