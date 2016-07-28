module Seek
  module Samples
    module AttributeTypeHandlers
      class IceIdAttributeTypeHandler < BaseAttributeHandler
        def test_value(value)
          fail 'Not a valid SynBioChem ICE ID' unless value.match(/SBC[A-Za-z0-9]+/)
        end
      end

      def convert(value)
        value.strip
      end
    end
  end
end
