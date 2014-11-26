require File.join(File.dirname(__FILE__), 'abstract_resource')

module IIIF
  module Presentation
    class Layer < AbstractResource

      TYPE = 'sc:Layer'

      def required_keys
        super + %w{ @id label }
      end

      def array_only_keys
        super + %w{ other_content }
      end

      def string_only_keys
        super + %w{ viewing_direction } # should any of the any_type_keys be here?
      end

      def initialize(hsh={})
        hsh['@type'] = TYPE unless hsh.has_key? '@type'
        super(hsh)
      end

      def validate
        # Must all members of otherContent and images must be a URI (string), or
        # can they be inline?
        super
      end

    end
  end
end
