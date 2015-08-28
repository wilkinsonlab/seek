  module PersonRepresenter
    include Roar::JSON
    include Representable::Hash
    include Roar::Hypermedia
    include PersonStubRepresenter
  
#    property :id  
    property :title  
 end

