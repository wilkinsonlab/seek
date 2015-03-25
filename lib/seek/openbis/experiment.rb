module Seek
  module Openbis
    class Experiment < Entity

      attr_reader :experiment_type,:experiment_id,:sample_ids, :identifier

      def populate_from_json(json)
        @experiment_type=json["experiment_type"]
        @dataset_ids = json["datasets"]
        @sample_ids = json["samples"]
        @identifier=json["identifier"]
        super(json)
      end

      def experiment_type_description
        experiment_type["description"]
      end

      def experiment_type_code
        experiment_type["code"]
      end

      def experiment_type_text
        txt = experiment_type_description
        txt = experiment_type_code if txt.blank?
        txt
      end

      def comment
        properties["COMMENT"] || ""
      end

      def samples
        unless @samples
          @samples = sample_ids.collect do |id|
            Seek::Openbis::Zample.new(id)
          end
        end
        @samples
      end

      def datasets
        unless @datasets
          @datasets = sample_ids.collect do |id|
            Seek::Openbis::Dataset.new(id)
          end
        end
        @datasets
      end



      def type_name
        'Experiment'
      end

    end
  end
end