module IIIF
  module V3
    module Presentation
      class Manifest < IIIF::V3::AbstractResource

        TYPE = 'Manifest'.freeze

        def required_keys
          # NOTE:  relaxing requirement for items as Universal Viewer currently only accepts sequences
          #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
          # super + %w{ id label items }
          super + %w{ id label }
        end

        def prohibited_keys
          super + CONTENT_RESOURCE_PROPERTIES + PAGING_PROPERTIES + %w{ start_canvas content_annotation }
        end

        def uri_only_keys
          super + %w{ id }
        end

        def array_only_keys
          # NOTE: allowing 'items' or 'sequences' as Universal Viewer currently only accepts sequences
          #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
          # super + %w{ items structures }
          super + %w{ items structures sequences }
        end

        def legal_viewing_hint_values
          %w{ individuals paged continuous auto-advance }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super # also checks navDate format

          unless self['id'] =~ /^https?:/
            err_msg = "id must be an http(s) URI for #{self.class}"
            raise IIIF::V3::Presentation::IllegalValueError, err_msg
          end

          # Items object list
          unless self&.[]('items')&.any?
            m = 'The items list must have at least one entry (and it must be a IIIF::V3::Presentation::Canvas)'
            raise IIIF::V3::Presentation::MissingRequiredKeyError, m
          end
          validate_items_list(self['items']) if self['items']

          # TODO: when embedding a sequence without any extensions within a manifest, the sequence must not have the @context field.

          # TODO: AnnotationLists must not be embedded within the manifest

          if self['structures']
            unless self['structures'].all? { |entry| entry.instance_of?(IIIF::V3::Presentation::Range)}
              m = 'All entries in the structures list must be a IIIF::V3::Presentation::Range'
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end

        def validate_items_list(items_array)
          unless items_array.size >= 1
            m = 'The items list must have at least one entry (and it must be a IIIF::V3::Presentation::Canvas)'
            raise IIIF::V3::Presentation::MissingRequiredKeyError, m
          end

          unless items_array.all? { |entry| entry.instance_of?(IIIF::V3::Presentation::Canvas) }
            m = 'All entries in the items list must be a IIIF::V3::Presentation::Canvas'
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end
    end
  end
end
