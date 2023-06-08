require File.join(File.dirname(__FILE__), 'abstract_resource')

module IIIF
  module Presentation
    # https://iiif.io/api/presentation/3.0/#start
    class Start < AbstractResource
      def required_keys
        super + %w{ id }
      end
    end
  end
end
