module IIIF
  module V3
    module Presentation
      class Sequence < IIIF::V3::AbstractResource

        TYPE = 'Sequence'.freeze

        def required_keys
          super + %w{ items }
        end

        def prohibited_keys
          super + CONTENT_RESOURCE_PROPERTIES + PAGING_PROPERTIES + %w{ nav_date content_annotations }
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

          unless self['items'].size >= 1
            m = 'The items list must have at least one entry (and it must be a IIIF::V3::Presentation::Canvas)'
            raise IIIF::V3::Presentation::MissingRequiredKeyError, m
          end

          unless self['items'].all? { |entry| entry.instance_of?(IIIF::V3::Presentation::Canvas) }
            m = 'All entries in the items list must be a IIIF::V3::Presentation::Canvas'
            raise IIIF::V3::Presentation::IllegalValueError, m
          end

          # TODO: startCanvas: A link from a Sequence or Range to a Canvas that is contained within it

          # TODO: All external Sequences must have a dereference-able http(s) URI
        end
      end
    end
  end
end
