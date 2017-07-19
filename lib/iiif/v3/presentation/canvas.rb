module IIIF
  module V3
    module Presentation
      class Canvas < IIIF::V3::AbstractResource

        TYPE = 'Canvas'.freeze

        def required_keys
          super + %w{ id label }
        end

        def prohibited_keys
          super + PAGING_PROPERTIES + %w{ viewing_direction format nav_date start_canvas content_annotations }
        end

        def int_only_keys
          super + %w{ depth }
        end

        def array_only_keys
          super + %w{ content }
        end

        def legal_viewing_hint_values
          super + %w{ paged continuous non-paged facing-pages auto-advance }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super

          id_uri = URI.parse(self['id'])
          unless self['id'] =~ /^https?:/ && id_uri.fragment.nil?
            err_msg = "id must be an http(s) URI without a fragment for #{self.class}"
            raise IIIF::V3::Presentation::IllegalValueError, err_msg
          end

          content = self['content']
          if content && content.any?
            unless content.all? { |entry| entry.instance_of?(IIIF::V3::Presentation::AnnotationPage) }
              err_msg = 'All entries in the content list must be a IIIF::V3::Presentation::AnnotationPage'
              raise IIIF::V3::Presentation::IllegalValueError, err_msg
            end
          end

          # "A canvas MUST have exactly one width and one height, or exactly one duration.
          # It may have width, height and duration.""
          height = self['height']
          width = self['width']
          extent_err_msg = "#{self.class} must have (a height and a width) and/or a duration"
          if (!!height ^ !!width) # this is an exclusive or: forces height and width to boolean
            raise IIIF::V3::Presentation::IllegalValueError, extent_err_msg
          end
          duration = self['duration']
          unless (height && width) || duration
            raise IIIF::V3::Presentation::IllegalValueError, extent_err_msg
          end

          # TODO: Content must not be associated with space or time outside of the Canvas’s dimensions,
          # such as at coordinates below 0,0, greater than the height or width, before 0 seconds, or after the duration.
        end
      end
    end
  end
end
