module IIIF
  module V3
    module Presentation
      class AnnotationCollection < IIIF::V3::AbstractResource

        TYPE = 'AnnotationCollection'

        def required_keys
          super + %w{ id }
        end

        def int_only_keys
          super + %w{ total }
        end

        def array_only_keys
          super + %w{ content }
        end

        def string_only_keys
          # first and last are actually uris
          super + %w{ viewing_direction, first, last }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super
        end
      end
    end
  end
end
