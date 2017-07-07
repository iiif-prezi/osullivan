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

        def uri_only_keys
          super + %w{ first last }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

      end
    end
  end
end
