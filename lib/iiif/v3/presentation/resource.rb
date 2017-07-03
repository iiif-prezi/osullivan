module IIIF
  module V3
    module Presentation
      class Resource < IIIF::V3::AbstractResource

        def required_keys
          %w{ id }
        end

        def string_only_keys
          super + %w{ format }
        end

        def numeric_only_keys
          super + %w{ duration }
        end

      end
    end
  end
end
