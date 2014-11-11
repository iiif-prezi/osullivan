# Doing this to make Travis happy. It seems to not always find everything if
# the tests run in the wrong order
Dir["#{File.dirname(__FILE__)}/*.rb"].each do |f|
  require f
end

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

      def initialize(hsh={})
        hsh['@type'] = TYPE unless hsh.has_key? '@type'
        super(hsh)
      end

      def legal_viewing_hint_values
        %w{ individuals paged continuous }
      end

      def validate
        # TODO here:
        # * Must be at least one canvas
        # * All members of canvases must be a kind of Canvas
        super
      end

    end
  end
end

