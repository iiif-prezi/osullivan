module IIIF
  module V3
    module Presentation
      class AnnotationPage < IIIF::V3::AbstractResource

        TYPE = 'AnnotationPage'

        def required_keys
          super + %w{ id }
        end

        def array_only_keys;
          super + %w{ items };
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super
          # TODO: Each member or resources must be a kind of Annotation
        end

      end
    end
  end
end
