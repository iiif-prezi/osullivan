module IIIF
  module V3
    module Presentation
      class Collection < IIIF::V3::AbstractResource
        TYPE = 'Collection'.freeze

        def required_keys
          super + %w[id label]
        end

        def array_only_keys
          super + %w[collections manifests]
        end

        # TODO: navDate (collection or manifest only) - The value must be an xsd:dateTime literal in UTC, expressed in the form “YYYY-MM-DDThh:mm:ssZ”;  There must be at most one navDate associated with any given resource.

        # TODO: paging properties
        # Collection, AnnotationCollection, (formerly layer --> AnnotationPage???) allow;  forbidden o.w.
        # ---
        # first, last, next, prev
        #   id is URI, but may have other info
        # total, startIndex
        #   The value must be a non-negative integer.

        def legal_viewing_hint_values
          %w[auto-advance together]
        end

        def initialize(hsh = {})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super
          # TODO: each member of collections and manifests must be a Hash
          # TODO: each member of collections and manifests MUST have id, type, and label
          # TODO: navDate (collection or manifest only) - The value must be an xsd:dateTime literal in UTC, expressed in the form “YYYY-MM-DDThh:mm:ssZ”;  There must be at most one navDate associated with any given resource.

          # TODO: paging properties
          # Collection, AnnotationCollection, (formerly layer --> AnnotationPage???) allow;  forbidden o.w.
          # ---
          # first, last, next, prev
          #   id is URI, but may have other info
          # total, startIndex
          #   The value must be a non-negative integer.
        end
      end
    end
  end
end
