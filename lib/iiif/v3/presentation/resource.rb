module IIIF
  module V3
    module Presentation
      # class for generic content resource
      class Resource < IIIF::V3::AbstractResource

        def required_keys
          super + %w{ id }
        end

        def prohibited_keys
          super + PAGING_PROPERTIES + %w{ nav_date viewing_direction start_canvas content_annotations}
        end

        def validate
          super

          unless self['id'] =~ /^https?:/
            err_msg = "id must be an http(s) URI for #{self.class}"
            raise IIIF::V3::Presentation::IllegalValueError, err_msg
          end
        end
      end
    end
  end
end
