module Seek
  module Openbis
    class Zample < Entity

      attr_reader :sample_type,:experiment_id,:dataset_ids,:identifier

      def populate_from_json(json)
        @sample_type=json["sample_type"]
        @dataset_ids = json["datasets"]
        @experiment_id = json["experiment"]
        @identifier=json["identifier"]
        super(json)
      end

      def datasets
        unless @datasets
          @datasets = dataset_ids.collect do |id|
            Seek::Openbis::Dataset.new(id)
          end
        end
        @datasets.sort_by(&:modification_date).reverse
      end

      def sample_type_text
        txt = sample_type_description
        txt = sample_type_code if txt.blank?
        txt
      end

      def sample_type_description
        sample_type["description"]
      end

      def sample_type_code
        sample_type["code"]
      end

      def type_name
        'Sample'
      end

    end
  end
end