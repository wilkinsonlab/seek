module Seek
  module Openbis
    class DatasetFile

      attr_reader :json

      def files
        files = []
        @json["datasetfiles"][0].each do |json_file|
          files << file json_file
        end
      end

      def file json_file
        path = json_file["path"]
        size = json_file["fileLength"].last
        is_directory = json_file["isDirectory"]
        dataset_id = json_file["dataset"]
        {:path=>path,:size=>size,:dataset_id=>dataset_id,:is_directory=>json_file[]}
      end

      def query_datastore_server_by_perm_id perm_id=""
        cache_key = "openbis-datastore-server-#{type_name}-#{Digest::SHA2.hexdigest(perm_id)}"
        Rails.cache.fetch(cache_key) do
          @json = datastore_server_query_instance.query({:entityType=>type_name,:queryType=>"ATTRIBUTE",:attribute=>"PermID",:attributeValue=>perm_id})
          @json
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