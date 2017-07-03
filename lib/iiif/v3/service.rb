require_relative 'abstract_resource'

module IIIF
  module V3
    class Service < AbstractResource

      # service is the only class that doesn't need a type
      def required_keys
        super.reject {|el| el == 'type' }
      end

      def initialize(hsh={})
        super(hsh)
      end

    end
  end
end
