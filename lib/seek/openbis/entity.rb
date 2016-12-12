module Seek
  module Openbis
    class Entity

      attr_reader :json,:modifier,:registration_date,:modification_date,:code,:perm_id,:registrator

      def self.all
        self.new.all
      end

      def self.find_by_perm_ids perm_ids
        self.new.find_by_perm_ids(perm_ids)
      end

      def ==(other)
        self.perm_id == other.perm_id
      end

      def initialize(perm_id=nil)
        if (perm_id)
          json = query_application_server_by_perm_id(perm_id)
          if !json[json_key]
            raise Seek::Openbis::EntityNotFoundException.new("Unable to find #{type_name} with perm id #{perm_id}")
          end
          populate_from_json(json[json_key].first)
        end
      end

      def populate_from_json(json)
        @json=json
        @modifier=json["modifier"]
        @code=json["code"]
        @perm_id=json["permId"]
        @registrator=json["registerator"]
        @registration_date=Time.at(json["registrationDate"].to_i/1000).to_datetime
        @modification_date=Time.at(json["modificationDate"].to_i/1000).to_datetime
        self
      end

      def all
        json = query_application_server_by_perm_id
        construct_from_json(json)
      end

      def construct_from_json(json)
        json[json_key].collect do |json|
          self.class.new.populate_from_json(json)
        end.sort_by(&:modification_date).reverse
      end

      def find_by_perm_ids perm_ids
        ids_str=perm_ids.compact.uniq.join(",")
        json = query_application_server_by_perm_id(ids_str)
        construct_from_json(json)
      end

      def comment
        properties["COMMENT"] || ""
      end

      def query_application_server_by_perm_id perm_id=""
        Rails.cache.fetch(cache_key(perm_id)) do
          application_server_query_instance.query({:entityType=>type_name,:queryType=>"ATTRIBUTE",:attribute=>"PermID",:attributeValue=>perm_id})
        end
      end

      def cache_key perm_id
        "openbis-application-server-#{type_name}-#{Digest::SHA2.hexdigest(perm_id)}"
      end

      def application_server_query_instance
        info = Seek::Openbis::ConnectionInfo.instance
        Fairdom::OpenbisApi::ApplicationServerQuery.new(info.as_endpoint, info.session_token)
      end

      def samples
        unless @samples
          @samples = Seek::Openbis::Zample.find_by_perm_ids(sample_ids)
        end
        @samples
      end

      def datasets
        unless @datasets
          @datasets = dataset_ids.collect do |id|
            Seek::Openbis::Dataset.new(id)
          end
        end
        @datasets
      end

      #provides the number of datasets without having to fetch and construct as you would with datasets.count
      def dataset_count
        dataset_ids.count
      end

      protected

      def json_key
        type_name.downcase.pluralize
      end

      private

      def dataset_ids
        json['datasets']
      end

    end
  end
end