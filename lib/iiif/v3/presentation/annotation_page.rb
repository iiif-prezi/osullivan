module IIIF
  module V3
    module Presentation
      class AnnotationPage < IIIF::V3::AbstractResource
        TYPE = 'AnnotationPage'.freeze

        def required_keys
          super + %w[id]
        end

        def prohibited_keys
          super + CONTENT_RESOURCE_PROPERTIES +
            %w[first last total nav_date viewing_direction start_canvas content_annotations]
        end

        def uri_only_keys
          super + %w[id]
        end

        def array_only_keys
          super + %w[items]
        end

        def legal_viewing_hint_values
          super + %w[none]
        end

        def initialize(hsh = {})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super

          unless self['id'] =~ /^https?:/
            err_msg = "id must be an http(s) URI for #{self.class}"
            raise IIIF::V3::Presentation::IllegalValueError, err_msg
          end

          items = self['items']
          return unless items && items.any?
          return if items.all? { |entry| entry.instance_of?(IIIF::V3::Presentation::Annotation) }

          err_msg = 'All entries in the items list must be a IIIF::V3::Presentation::Annotation'
          raise IIIF::V3::Presentation::IllegalValueError, err_msg
        end
      end
    end
  end
end
