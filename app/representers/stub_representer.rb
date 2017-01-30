  module StubRepresenter
    include Roar::JSON
    include Representable::Hash
    include Roar::Hypermedia
    include Roar::JSON::HAL::Links

    property :url_for_self, as: :url

  def url_for_self
    url_for self
  end

  end
