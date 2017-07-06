module IIIF
  module V3
    module Presentation
      # See http://prezi3.iiif.io/api/annex/services for more info
      class Service < AbstractResource

        # constants included here for convenience
        IIIF_IMAGE_V2_CONTEXT = 'http://iiif.io/api/image/2/context.json'.freeze
        IIIF_IMAGE_V2_LEVEL1_PROFILE = 'http://iiif.io/api/image/2/level1.json'.freeze
        IIIF_AUTHENTICATION_V1_LOGIN_PROFILE = 'http://iiif.io/api/auth/1/login'.freeze
        IIIF_AUTHENTICATION_V1_TOKEN_PROFILE = 'http://iiif.io/api/auth/1/token'.freeze

        # service class doesn't require type
        def required_keys
          super.reject {|el| el == 'type' }
        end

        def prohibited_keys
          super + CONTENT_RESOURCE_PROPERTIES + PAGING_PROPERTIES +
            %w{ nav_date viewing_direction start_canvas content_annotation }
        end

        def uri_only_keys
          super + %w{ @context id @id }
        end

        def validate
          super
          if IIIF_IMAGE_V2_CONTEXT == self['@context']
            unless self.has_key?('@id')
              m = "@id is required for IIIF::V3::Presentation::Service with @context #{IIIF_IMAGE_V2_CONTEXT}"
              raise IIIF::V3::Presentation::MissingRequiredKeyError, m
            end
            unless self.has_key?('profile')
              m = "profile is required for IIIF::V3::Presentation::Service with @context #{IIIF_IMAGE_V2_CONTEXT}"
              raise IIIF::V3::Presentation::MissingRequiredKeyError, m
            end
          end
        end
      end
    end
  end
end
