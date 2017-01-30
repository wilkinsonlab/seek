module DisciplineRepresenter
    include Roar::JSON
    include Representable::Hash
    include Roar::Hypermedia

    property :title
end
