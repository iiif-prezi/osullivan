require File.join(File.dirname(__FILE__), 'sequence')

module IIIF
  module V3
    module Presentation
      class Range < Sequence

        TYPE = 'Range'

        def required_keys
          super + %w{ id label }
        end

        def array_only_keys
          super + %w{ members }
        end

        def legal_viewing_hint_values
          super + %w{ top }
        end

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def validate
          # Values of the members array must be canvas or range
        end
      end
    end
  end
end
