module IIIF
  module V3
    module Presentation
      class Choice < IIIF::V3::AbstractResource

        TYPE = 'Choice'

        def string_only_keys
          super + %w{ choice_hint }
        end

        def array_only_keys;
          super + %w{ items };
        end

        def legal_viewing_hint_values
          %w{ none }
        end

        def legal_choice_hint_values
          %w{ client user }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          super

          # time mode values
          if self.has_key?('choice_hint')
            unless self.legal_choice_hint_values.include?(self['choice_hint'])
              m = "choiceHint for #{self.class} must be one of #{self.legal_choice_hint_values}."
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end
      end
    end
  end
end
