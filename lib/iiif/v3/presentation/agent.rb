module IIIF
  module V3
    module Presentation
      class Agent < IIIF::V3::Presentation::Resource

        TYPE = 'Agent'.freeze

        def initialize(hsh={})
          hsh['type'] = TYPE unless hsh.has_key? 'type'
          super(hsh)
        end

        def required_keys
          super + %w{ label }
        end

      end
    end
  end
end