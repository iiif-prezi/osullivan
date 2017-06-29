require File.join(File.dirname(__FILE__), 'abstract_resource')

module IIIF
  module V3
    module Presentation
      class Annotation < AbstractResource

        TYPE = 'Annotation'

        def required_keys
          super + %w{ motivation }
        end

        def abstract_resource_only_keys
          super + [ { key: 'body', type: IIIF::V3::Presentation::Resource } ]
        end

        def string_only_keys
          super + %w{ time_mode }
        end

        def legal_time_mode_values
          %w{ trim scale loop }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          hsh['motivation'] = 'painting' unless hsh.has_key? 'motivation'
          super(hsh)
        end

        def validate
          super

          # time mode values
          if self.has_key?('time_mode')
            unless self.legal_time_mode_values.include?(self['time_mode'])
              m = "timeMode for #{self.class} must be one of #{self.legal_time_mode_values}."
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end
      end
    end
  end
end
