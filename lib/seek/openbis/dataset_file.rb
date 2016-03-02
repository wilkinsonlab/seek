module Seek
  module Openbis
    class DatasetFile

      attr_reader :dataset_id,:file_id,:path,:is_directory,:file_length

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
        'DataSetFile'
      end
    end
  end
end