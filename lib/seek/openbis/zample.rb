module Seek
  module Openbis
    class Zample < Entity

      attr_reader :sample_type,:experiment_id,:dataset_ids

      def populate_from_json(json)
        super(json)
        @sample_type=json["sample_type"]
        @dataset_ids = json["datasets"]
        @experiment_id = json["experiment"]
        self
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