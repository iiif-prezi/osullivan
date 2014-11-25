require File.join(File.dirname(__FILE__), 'abstract_resource')

module IIIF
  module Presentation
    class Canvas < AbstractResource

      # TODO (?) a simple 'Image Canvas' constructor.

      TYPE = 'sc:Canvas'

      def required_keys
        super + %w{ @id width height label }
      end

      def any_type_keys
        super + %w{  }
      end

      def array_only_keys
        super + %w{ images other_content }
      end

      # TODO: test and validate
      def int_only_keys
        super + %w{ width height }
      end

      def legal_viewing_hint_values
        super + %w{ non-paged }
      end

      def initialize(hsh={})
        hsh['@type'] = TYPE unless hsh.has_key? '@type'
        super(hsh)
      end

      def validate
        # all members of images must be an annotation
        # all members of otherContent must be an annotation list
        super
      end

    end
  end
end
