module Seek
  module Openbis
    class Experiment < Entity

      attr_reader :experiment_type,:experiment_id,:sample_ids

      def populate_from_json(json)
        super(json)
        @experiment_type=json["experiment_type"]
        @dataset_ids = json["datasets"]
        @sample_ids = json["samples"]
        self
      end

      def experiment_type_description
        experiment_type["description"]
      end

      def experiment_type_code
        experiment_type["code"]
      end



      def type_name
        'Experiment'
      end

      # sample and dataset stuff
      # @datasets=[]
      # json["datasets"].each do |id|
      #   @datasets << Seek::Openbis::Dataset.new(id)
      # end
      # @samples=[]
      # json["samples"].each do |id|
      #   @samples << Seek::Openbis::Zample.new(id)
      #end
    end
  end
end