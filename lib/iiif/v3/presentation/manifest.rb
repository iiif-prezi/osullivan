module IIIF
  module V3
    module Presentation
      class Manifest < IIIF::V3::AbstractResource

        TYPE = 'Manifest'

        def required_keys
          super + %w{ id label }
        end

        def array_only_keys
          super + %w{ sequences structures }
        end

        def legal_viewing_hint_values
          %w{ individuals paged continuous auto-advance none }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super
          # TODO: check types of sequences and structure members
        end
      end
    end
  end
end
