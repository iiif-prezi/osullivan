require File.join(File.dirname(__FILE__), 'resource')

module IIIF
  module Presentation
    class ImageResource < Resource

      TYPE = 'dctypes:Image'

      def int_only_keys
        super + %w{ width height }
      end

      def initialize(hsh={})
        hsh['@type'] = 'dcterms:Image' unless hsh.has_key? '@type'
        super(hsh)
      end

    end
  end
end
