module IIIF
  module V3
    module Presentation
      # Ranges are linked or embedded within the manifest in a structures field
      class Range < Sequence
        TYPE = 'Range'.freeze
        VALID_ITEM_TYPES = [IIIF::V3::Presentation::Canvas, IIIF::V3::Presentation::Range]

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
          validate_list(self['items']) if self['items']
          validate_list(self['canvases']) if self['canvases']
          # TODO: Ranges must have URIs and they should be http(s) URIs.
          # TODO: contentAnnotations: links to AnnotationCollection
          # TODO: startCanvas: A link from a Sequence or Range to a Canvas that is contained within it
        end

        private

        def validate_list(canvas_array)
          return if canvas_array.all? { |entry| VALID_ITEM_TYPES.include?(entry.class) }

          m = "All entries in the (items or canvases) array must be one of #{VALID_ITEM_TYPES.join(', ')}"
          raise IIIF::V3::Presentation::IllegalValueError, m
        end
      end
    end
  end
end
