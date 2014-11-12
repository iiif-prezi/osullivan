Dir["#{File.dirname(__FILE__)}/*.rb"].each do |f|
  require f
end
require File.join(File.dirname(__FILE__), '../../active_support/ordered_hash')


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

      def initialize(hsh={}, include_context=false)
        hsh['@type'] = TYPE unless hsh.has_key? '@type'
        super(hsh, include_context)
      end

    end
  end
end
