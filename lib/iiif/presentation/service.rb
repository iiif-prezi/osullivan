require File.join(File.dirname(__FILE__), 'abstract_resource')

module IIIF
  module Presentation
    class Service < AbstractResource
      def required_keys
        []
      end
    end
  end
end
