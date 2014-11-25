require File.join(File.dirname(__FILE__), 'abstract_resource')

module IIIF
  module Presentation
    class Sequence < AbstractResource

      TYPE = 'sc:Sequence'

      def array_only_keys
        super + %w{ canvases }
      end

      def string_only_keys
        super + %w{ start_canvas viewing_direction }
      end

      def legal_viewing_hint_values
        %w{ individuals paged continuous }
      end

      def initialize(hsh={})
        hsh['@type'] = TYPE unless hsh.has_key? '@type'
        super(hsh)
      end

      def validate
        # * Must be at least one canvas
        # * All members of canvases must be a kind of Canvas
        super
      end

    end
  end
end

