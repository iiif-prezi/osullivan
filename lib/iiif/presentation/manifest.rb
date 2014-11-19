require File.join(File.dirname(__FILE__), 'abstract_resource')

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
        %w{ individuals paged continuous }
      end

      def initialize(hsh={})
        hsh['@type'] = TYPE unless hsh.has_key? '@type'
        super(hsh)
      end

      def validate
        # TODO: check types of sequences and structure members

        super
      end

    end
  end
end

