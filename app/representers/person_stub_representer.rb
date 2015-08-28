  module PersonStubRepresenter
    include Roar::JSON
    include Representable::Hash
    include Roar::Hypermedia
  
    property :id
    link :url do person_url self end
  end
