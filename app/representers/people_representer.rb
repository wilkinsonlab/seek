  module PeopleRepresenter

    include Representable::JSON::Collection

    include BaseRepresenter

    items extend: StubRepresenter, class: Person, wrap: false

    def items
      ["Fred"]
    end
  end
