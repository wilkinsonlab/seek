  module PersonStubRepresenter
    include Roar::JSON
    include Representable::Hash
    include Roar::Hypermedia
  
    include BaseRepresenter

    property :id
    link :url do url_for self end
  end
