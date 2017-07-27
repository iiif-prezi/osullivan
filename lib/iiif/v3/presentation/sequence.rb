module IIIF
  module V3
    module Presentation
      class Sequence < IIIF::V3::AbstractResource

        TYPE = 'Sequence'.freeze

        # NOTE:  relaxing requirement for items as Universal Viewer currently only accepts canvases
        #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
        # def required_keys
        #   super + %w{ items }
        # end

        def prohibited_keys
          super + CONTENT_RESOURCE_PROPERTIES + PAGING_PROPERTIES + %w{ nav_date content_annotations }
        end

        # NOTE: allowing 'items' or 'canvases' as Universal Viewer currently only accepts canvases
        #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
        def array_only_keys
          super + %w{ canvases }
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

          # Canvas object list
          # NOTE: allowing 'items' or 'canvases' as Universal Viewer currently only accepts canvases
          #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
          unless (self['items'] && self['items'].any?) ||
              (self['canvases'] && self['canvases'].any?)
            m = 'The (items or canvases) list must have at least one entry (and it must be a IIIF::V3::Presentation::Canvas)'
            raise IIIF::V3::Presentation::MissingRequiredKeyError, m
          end
          validate_canvas_list(self['items']) if self['items']
          validate_canvas_list(self['canvases']) if self['canvases']

          # TODO: startCanvas: A link from a Sequence or Range to a Canvas that is contained within it

          # TODO: All external Sequences must have a dereference-able http(s) URI
        end

        def validate_canvas_list(canvas_array)
          unless canvas_array.size >= 1
            m = 'The (items or canvases) list must have at least one entry (and it must be a IIIF::V3::Presentation::Canvas)'
            raise IIIF::V3::Presentation::MissingRequiredKeyError, m
          end

          unless canvas_array.all? { |entry| entry.instance_of?(IIIF::V3::Presentation::Canvas) }
            m = 'All entries in the (items or canvases) list must be a IIIF::V3::Presentation::Canvas'
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end
    end
  end
end
