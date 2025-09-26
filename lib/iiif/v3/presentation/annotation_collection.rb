module IIIF
  module V3
    module Presentation
      class AnnotationCollection < IIIF::V3::AbstractResource
        TYPE = 'AnnotationCollection'.freeze

        def required_keys
          super + %w[id]
        end

        def int_only_keys
          super + %w[total]
        end

        def array_only_keys
          super + %w[content]
        end

        # TODO: paging properties
        # Collection, AnnotationCollection, (formerly layer --> AnnotationPage???) allow;  forbidden o.w.
        # ---
        # first, last, next, prev
        #   id is URI, but may have other info
        # total, startIndex
        #   The value must be a non-negative integer.
        #
        # don't forget to validate

        def initialize(hsh = {})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end
      end
    end
  end
end
