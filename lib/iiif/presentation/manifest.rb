# Doing this to make Travis happy. It seems to not always find everything if
# the tests run in the wrong order
Dir["#{File.dirname(__FILE__)}/*.rb"].each do |f|
  require f
end

module IIIF
  module Presentation
    class Manifest < AbstractResource

      TYPE = 'sc:Manifest'

      def required_keys
        super + %w{ @id label }
      end

      def string_only_keys
        super + %w{ viewing_direction }
      end

      def array_only_keys
        super + %w{ sequences structures }
      end

      def legal_viewing_hint_values
        %w{individuals paged continuous }
      end

      def initialize(hsh={}, include_context=false)
        # make it possible to subclass, possibly with a different @type
        hsh['@type'] = TYPE unless hsh.has_key? '@type'
        super(hsh, include_context)
      end

      def validate
        super
      end

    end
  end
end

