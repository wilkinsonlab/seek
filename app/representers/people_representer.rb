  module PeopleRepresenter

    include Representable::JSON::Collection

    items extend:PersonStubRepresenter, class: Person
  end
