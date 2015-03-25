module Seek
  module Openbis
    class Dataset < Entity

      attr_reader :dataset_type,:experiment_id,:sample_ids

      def populate_from_json(json)
        super(json)
        @dataset_type=json["dataset_type"]
        @experiment_id = json["experiment"]
        @sample_ids = json["samples"]
        self
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

      def samples
        unless @samples
          @samples = sample_ids.collect do |id|
            Seek::Openbis::Zample.new(id)
          end
        end
        @samples
      end

      def type_name
        'DataSet'
      end
    end
  end
end