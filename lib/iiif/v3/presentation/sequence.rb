module IIIF
  module V3
    module Presentation
      class Sequence < IIIF::V3::AbstractResource

        TYPE = 'Sequence'

        def required_keys
          super + %w{ items }
        end

        def legal_viewing_hint_values
          %w{ individuals paged continuous auto-advance }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super
          # TODO: Must be at least one canvas
          # TODO: All members of canvases must be a kind of Canvas
        end
      end
    end
  end
end
