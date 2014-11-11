# Doing this to make Travis happy. It seems to not always find everything if
# the tests run in the wrong order
Dir["#{File.dirname(__FILE__)}/*.rb"].each do |f|
  require f
end

module IIIF
  module Presentation
    class Canvas < AbstractResource

      # TODO a simple 'Image Canvas' constructor.

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

      def string_only_keys
        super + %w{ viewing_hint }
      end

      # TODO: test and validate
      def int_only_keys
        super + %w{ width height }
      end

      def legal_viewing_hint_values
        super + %w{ non-paged }
      end

      def initialize(hsh={})
        # make it possible to subclass, possibly with a different @type
        hsh['@type'] = TYPE unless hsh.has_key? '@type'
        super(hsh)
      end

      def validate
        # Each sequence must have a label if there is more than one
        super
      end

    end
  end
end
