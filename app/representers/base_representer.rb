  module BaseRepresenter
    include Roar::JSON
    include Representable::Hash
    include Roar::Hypermedia

    property :json_api_version

    def json_api_version
      '0.0.1'
    end

end
