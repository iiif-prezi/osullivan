require File.join(File.dirname(__FILE__), 'abstract_resource')

module IIIF
  module V3
    module Presentation
      class Canvas < AbstractResource

        # TODO (?) a simple 'Image Canvas' constructor.

        TYPE = 'Canvas'

        def required_keys
          super + %w{ id label }
        end

        def any_type_keys
          super + %w{  }
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
          # all members of content are of type AnnotationPage
          super
        end
      end
    end
  end
end
