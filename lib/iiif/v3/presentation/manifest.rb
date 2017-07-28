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

          # Sequence object list
          # NOTE: allowing 'items' or 'sequences' as Universal Viewer currently only accepts sequences
          #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
          unless (self['items'] && self['items'].any?) ||
            (self['sequences'] && self['sequences'].any?)
            m = 'The (items or sequences) list must have at least one entry (and it must be a IIIF::V3::Presentation::Sequence)'
            raise IIIF::V3::Presentation::MissingRequiredKeyError, m
          end
          validate_sequence_list(self['items']) if self['items']
          validate_sequence_list(self['sequences']) if self['sequences']

          # TODO: when embedding a sequence without any extensions within a manifest, the sequence must not have the @context field.

          # TODO: AnnotationLists must not be embedded within the manifest

          if self['structures']
            unless self['structures'].all? { |entry| entry.instance_of?(IIIF::V3::Presentation::Range)}
              m = 'All entries in the structures list must be a IIIF::V3::Presentation::Range'
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end

        # NOTE: allowing 'items' or 'sequences' as Universal Viewer currently only accepts sequences
        #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
        def validate_sequence_list(sequence_array)
          unless sequence_array.size >= 1
            m = 'The (items or sequences) list must have at least one entry (and it must be a IIIF::V3::Presentation::Sequence)'
            raise IIIF::V3::Presentation::MissingRequiredKeyError, m
          end

          unless sequence_array.all? { |entry| entry.instance_of?(IIIF::V3::Presentation::Sequence) }
            m = 'All entries in the (items or sequences) list must be a IIIF::V3::Presentation::Sequence'
            raise IIIF::V3::Presentation::IllegalValueError, m
          end

          default_sequence = sequence_array.first
          # NOTE: allowing 'items' or 'canvases' as Universal Viewer currently only accepts canvases
          #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
          canvas_array = default_sequence['items'] || default_sequence['canvases']
          unless canvas_array && canvas_array.size >= 1 &&
            canvas_array.all? { |entry| entry.instance_of?(IIIF::V3::Presentation::Canvas) }
            m = 'The default Sequence (the first entry of (items or sequences)) must be written out in full within the Manifest file'
            raise IIIF::V3::Presentation::IllegalValueError, m
          end

          if sequence_array.size > 1
            unless sequence_array.all? { |entry| entry['label'] }
              m = 'If there are multiple Sequences in a manifest then they must each have at least one label'
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end
      end
    end
  end
end
