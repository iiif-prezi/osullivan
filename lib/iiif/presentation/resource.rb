require File.join(File.dirname(__FILE__), 'abstract_resource')

module IIIF
  module Presentation
    class Resource < AbstractResource

      def required_keys
        %w{ @id }
      end

      def string_only_keys
        super + %w{ format }
      end

      def initialize(hsh={})
        super(hsh)
      end

    end
  end
end
