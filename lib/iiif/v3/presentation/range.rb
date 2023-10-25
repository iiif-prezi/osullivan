module IIIF
  module V3
    module Presentation
      # Ranges are linked or embedded within the manifest in a structures field
      class Range < Sequence

        TYPE = 'Range'.freeze

        def required_keys
          super + %w{ id label }
        end

        # TODO: contentAnnotations: links to AnnotationCollection
        # TODO: startCanvas: A link from a Sequence or Range to a Canvas that is contained within it

        def array_only_keys
          super + %w{ members }
        end

        def legal_viewing_hint_values
          super + %w{ top }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super
          # TODO: Ranges must have URIs and they should be http(s) URIs.
          # TODO: Values of the members array must be canvas or range
          # TODO: contentAnnotations: links to AnnotationCollection
          # TODO: startCanvas: A link from a Sequence or Range to a Canvas that is contained within it
        end
      end
    end
  end
end
