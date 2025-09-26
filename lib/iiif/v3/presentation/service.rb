module IIIF
  module V3
    module Presentation
      # See http://prezi3.iiif.io/api/annex/services for more info
      class Service < AbstractResource
        # constants included here for convenience
        IIIF_IMAGE_V2_TYPE = 'ImageService2'.freeze
        IIIF_IMAGE_V2_LEVEL1_PROFILE = 'http://iiif.io/api/image/2/level1.json'.freeze
        IIIF_AUTHENTICATION_V1_LOGIN_PROFILE = 'http://iiif.io/api/auth/1/login'.freeze
        IIIF_AUTHENTICATION_V1_TOKEN_PROFILE = 'http://iiif.io/api/auth/1/token'.freeze

        # service class doesn't require type
        def required_keys
          super.reject { |el| el == 'type' }
        end

        def prohibited_keys
          super + CONTENT_RESOURCE_PROPERTIES + PAGING_PROPERTIES +
            %w[nav_date viewing_direction start_canvas content_annotations]
        end

        def uri_only_keys
          super + %w[@context id @id]
        end

        def any_type_keys
          super + %w[profile]
        end

        def validate
          super
          return unless IIIF_IMAGE_V2_TYPE == self['type'] || IIIF_IMAGE_V2_TYPE == self['@type']

          unless has_key?('id') || has_key?('@id')
            m = "id or @id values are required for IIIF::V3::Presentation::Service with type or @type #{IIIF_IMAGE_V2_TYPE}"
            raise IIIF::V3::Presentation::MissingRequiredKeyError, m
          end
          if has_key?('id') && has_key?('@id') && (self['@id'] != self['id'])
            m = "id and @id values must match for IIIF::V3::Presentation::Service with type or @type #{IIIF_IMAGE_V2_TYPE}"
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
          return if has_key?('profile')

          m = "profile should be present for IIIF::V3::Presentation::Service with type or @type #{IIIF_IMAGE_V2_TYPE}"
          raise IIIF::V3::Presentation::MissingRequiredKeyError, m
        end
      end
    end
  end
end
