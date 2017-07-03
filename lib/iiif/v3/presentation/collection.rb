module IIIF
  module V3
    module Presentation
      class Collection < IIIF::V3::AbstractResource

        TYPE = 'Collection'

        def required_keys
          super + %w{ id label }
        end

        def array_only_keys
          super + %w{ collections manifests }
        end

        def legal_viewing_hint_values
          %w{ auto-advance together }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super
          # TODO: each member of collections and manifests must be a Hash
          # TODO: each member of collections and manifests MUST have id, type, and label
        end
      end
    end
  end
end
