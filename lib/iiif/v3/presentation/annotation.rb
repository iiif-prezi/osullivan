module IIIF
  module V3
    module Presentation
      class Annotation < IIIF::V3::AbstractResource

        TYPE = 'Annotation'.freeze

        def required_keys
          super + %w{ id motivation target }
        end

        def prohibited_keys
          super + CONTENT_RESOURCE_PROPERTIES + PAGING_PROPERTIES +
          %w{ nav_date viewing_direction start_canvas content_annotations }
        end

        def any_type_keys
          super + %w{ body target }
        end

        def uri_only_keys
          super + %w{ id }
        end

        def string_only_keys
          super + %w{ motivation time_mode }
        end

        def legal_time_mode_values
          %w{ trim scale loop }.freeze
        end

        def legal_viewing_hint_values
          super + %w{ none }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          hsh['motivation'] = 'painting' unless hsh.has_key? 'motivation'
          super(hsh)
        end

        def validate
          super

          if self.has_key?('body') && self['body'].kind_of?(IIIF::V3::Presentation::ImageResource)
            img_res_class_str = "IIIF::V3::Presentation::ImageResource"

            unless self.motivation == 'painting'
              m = "#{self.class} motivation must be 'painting' when body is a kind of #{img_res_class_str}"
              raise IIIF::V3::Presentation::IllegalValueError, m
            end

            body_resource = self['body']
            body_id = body_resource['id']
            if body_id && body_id =~ /^https?:/
              validate_uri(body_id, 'anno body ImageResource id') # can raise IllegalValueError
            else
              m = "when #{self.class} body is a kind of #{img_res_class_str}, ImageResource id must be an http(s) URI"
              raise IIIF::V3::Presentation::IllegalValueError, m
            end

            body_service = *body_resource['service']
            body_service_context = *body_resource['service']['@context']
            expected_context = IIIF::V3::Presentation::Service::IIIF_IMAGE_V2_CONTEXT
            unless body_service && body_service_context && body_service_context.include?(expected_context)
              m = "when #{self.class} body is a kind of #{img_res_class_str}, ImageResource's service @context must include #{expected_context}"
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end

          if self.has_key?('time_mode')
            unless self.legal_time_mode_values.include?(self['time_mode'])
              m = "timeMode for #{self.class} must be one of #{self.legal_time_mode_values}."
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end
      end
    end
  end
end
