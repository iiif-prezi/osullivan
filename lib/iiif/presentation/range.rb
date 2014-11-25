require File.join(File.dirname(__FILE__), 'sequence')

module IIIF
  module Presentation
    class Range < Sequence

      TYPE = 'sc:Range'

      def required_keys
        super + %w{ @id label }
      end

      def array_only_keys
        super + %w{ ranges }
      end

      def legal_viewing_hint_values
        super + %w{ top }
      end

      def initialize(hsh={})
        hsh['@type'] = TYPE unless hsh.has_key? '@type'
        super(hsh)
      end

      def validate
        # Values of the ranges array must be strings
      end

    end
  end
end
