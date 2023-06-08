require File.join(File.dirname(__FILE__), 'abstract_resource')

module IIIF
  module Presentation
    class Service < AbstractResource
      def required_keys
        []
      end

      # def to_ordered_hash(opts={})
      #   result = data.except('service')
      #   if data['service']
      #     result['service'] = data['service'].map(&:to_ordered_hash)
      #   end
      #   result
      # end
    end
  end
end

