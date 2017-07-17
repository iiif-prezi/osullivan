module IIIF
  module V3
    module Presentation
      class Service < AbstractResource

        # service is the only class that doesn't need a type
        def required_keys
          super.reject {|el| el == 'type' }
        end

      end
    end
  end
end
