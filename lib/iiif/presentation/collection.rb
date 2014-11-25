require File.join(File.dirname(__FILE__), 'abstract_resource')

module IIIF
  module Presentation
    class Collection < AbstractResource

      TYPE = 'sc:Collection'

      def required_keys
        super + %w{ @id label }
      end

      def array_only_keys
        super + %w{ collections manifests }
      end

      def initialize(hsh={})
        hsh['@type'] = TYPE unless hsh.has_key? '@type'
        super(hsh)
      end

      def validate
        # each member of collections and manifests must be a Hash
        # each member of collections and manifests MUST have @id, @type, and label
      end

    end
  end
end
