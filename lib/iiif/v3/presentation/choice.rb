module IIIF
  module V3
    module Presentation
      class Choice < IIIF::V3::AbstractResource
        TYPE = 'Choice'.freeze

        def prohibited_keys
          super + CONTENT_RESOURCE_PROPERTIES + PAGING_PROPERTIES +
            %w[nav_date viewing_direction start_canvas content_annotations]
        end

        def any_type_keys
          super + %w[default]
        end

        def string_only_keys
          super + %w[choice_hint]
        end

        def array_only_keys
          super + %w[items]
        end

        def legal_viewing_hint_values
          %w[none]
        end

        def legal_choice_hint_values
          %w[client user]
        end

        def initialize(hsh = {})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super

          return unless has_key?('choice_hint')
          return if legal_choice_hint_values.include?(self['choice_hint'])

          m = "choiceHint for #{self.class} must be one of #{legal_choice_hint_values}."
          raise IIIF::V3::Presentation::IllegalValueError, m
        end
      end
    end
  end
end
