module Seek
  module Openbis
    class Dataset < Entity

      attr_reader :dataset_type,:experiment_id,:sample_ids

      def populate_from_json(json)
        @dataset_type=json["dataset_type"]
        @experiment_id = json["experiment"]
        @sample_ids = json["samples"].last
        super(json)
      end

      def dataset_type_text
        txt = dataset_type_description
        txt = dataset_type_code if txt.blank?
        txt
      end

      def dataset_type_description
        dataset_type["description"]
      end

      def dataset_type_code
        dataset_type["code"]
      end

      def query_datastore_server_by_perm_id perm_id=""
        cache_key = "openbis-datastore-server-#{type_name}-#{Digest::SHA2.hexdigest(perm_id)}"
        Rails.cache.fetch(cache_key) do
          datastore_server_query_instance.query({:entityType=>type_name,:queryType=>"ATTRIBUTE",:attribute=>"PermID",:attributeValue=>perm_id})
        end
      end

      def download_by_perm_id type, perm_id, source, dest
        datastore_server_download_instance.download({:downloadType=>type,:permID=>perm_id,:source=>source,:dest=>dest})
      end

      def datastore_server_query_instance
        info = Seek::Openbis::ConnectionInfo.instance
        Fairdom::OpenbisApi::DataStoreQuery.new(info.dss_endpoint, info.session_token)
      end

      def datastore_server_download_instance
        info = Seek::Openbis::ConnectionInfo.instance
        Fairdom::OpenbisApi::DataStoreDownload.new(info.dss_endpoint, info.session_token)
      end

      def type_name
        'DataSet'
      end
    end
  end
end