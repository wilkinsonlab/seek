module Seek
  module Openbis
    class Entity

      attr_reader :json,:modifier,:registration_date,:modification_date,:code,:perm_id,:properties,:registrator

      def self.all
        self.new.all
      end

      def ==(other)
        self.perm_id == other.perm_id
      end

      def initialize(perm_id=nil)
        if (perm_id)
          populate_from_perm_id(perm_id)
        end
      end

      def populate_from_perm_id perm_id
        json = do_query_by_perm_id(perm_id)
        populate_from_json(json[json_key][0])
      end

      def populate_from_json(json)
        @json=json
        @modifier=json["modifier"]
        @code=json["code"]
        @perm_id=json["permId"]
        @properties=json["properties"]
        @registrator=json["registerator"]
        @registration_date=Time.at(json["registrationDate"].to_i/1000).to_datetime
        @modification_date=Time.at(json["modificationDate"].to_i/1000).to_datetime
        self
      end

      def all
        json = do_query_by_perm_id
        json[json_key].collect do |json|
          self.class.new.populate_from_json(json)
        end
      end

      def comment
        properties["COMMENT"] || ""
      end

      def do_query_by_perm_id perm_id=""
        cache_key = "openbis-#{type_name}-#{perm_id}"
        Rails.cache.fetch(cache_key) do
          query_instance.query({:type=>type_name,:attribute=>"permId",:attribute_value=>perm_id})
        end
      end

      def query_instance
        info = Seek::Openbis::ConnectionInfo.instance
        Fairdom::OpenbisApi::Query.new(info.username, info.password, info.endpoint)
      end

      protected

      def json_key
        type_name.downcase.pluralize
      end




    end
  end
end