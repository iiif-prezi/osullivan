module IIIF
  module V3
    module Presentation
      class Canvas < IIIF::V3::AbstractResource

        # TODO (?) a simple 'Image Canvas' constructor.

        TYPE = 'Canvas'

        def required_keys
          super + %w{ id label }
        end

        def array_only_keys
          super + %w{ content }
        end

        # TODO: test and validate
        def int_only_keys
          super + %w{ width height }
        end

        def legal_viewing_hint_values
          super + %w{ non-paged }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super
          # TODO: all members of content are of type AnnotationPage
        end
      end
    end
  end
end
