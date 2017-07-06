module IIIF
  module V3
    module Presentation
      class Manifest < IIIF::V3::AbstractResource

        TYPE = 'Manifest'.freeze

        def required_keys
          super + %w{ id label items }
        end

        def prohibited_keys
          super + CONTENT_RESOURCE_PROPERTIES + PAGING_PROPERTIES + %w{ start_canvas content_annotation }
        end

        def uri_only_keys
          super + %w{ id }
        end

        def array_only_keys
          super + %w{ items structures }
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

          unless self['items'].size >= 1
            m = 'The items list must have at least one entry (and it must be a IIIF::V3::Presentation::Sequence)'
            raise IIIF::V3::Presentation::MissingRequiredKeyError, m
          end

          unless self['items'].all? { |entry| entry.instance_of?(IIIF::V3::Presentation::Sequence) }
            m = 'All entries in the items list must be a IIIF::V3::Presentation::Sequence'
            raise IIIF::V3::Presentation::IllegalValueError, m
          end

          default_sequence = self['items'].first
          unless default_sequence['items'] && default_sequence['items'].size >=1 &&
            default_sequence['items'].all? { |entry| entry.instance_of?(IIIF::V3::Presentation::Canvas) }
            m = 'The default Sequence (the first entry of "items") must be written out in full within the Manifest file'
            raise IIIF::V3::Presentation::IllegalValueError, m
          end

          if self['items'].size > 1
            unless self['items'].all? { |entry| entry['label'] }
              m = 'If there are multiple Sequences in a manifest then they must each have at least one label'
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end

          # TODO: when embedding a sequence without any extensions within a manifest, the sequence must not have the @context field.

          # TODO: AnnotationLists must not be embedded within the manifest

          if self['structures']
            unless self['structures'].all? { |entry| entry.instance_of?(IIIF::V3::Presentation::Range)}
              m = 'All entries in the structures list must be a IIIF::V3::Presentation::Range'
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end
      end
    end
  end
end
