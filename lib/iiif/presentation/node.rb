module IIIF
  module Presentation
    class Node
      INITIALIZABLE_KEYS = ['@context', '@id', 'label']

      # Initialize a Presentation node
      # @param [Hash] hsh. '@context', '@id', and 'label' may be supplied when 
      #   initializing
    	def initialize(type, hsh={})
    		@data = []
        @data << ['@type', type]
        INITIALIZABLE_KEYS.each { |i| @data << [i, hsh[i]] if hsh.has_key? i }
        puts self.class

        # TODO: Something, like this:
        # https://github.com/projecthydra-labs/hydra-derivatives/blob/master/lib/hydra/derivatives/processor.rb#L12-L14
        # if this class (as opposed to a subclass) is initialized

    	end

      def to_hash
        Hash[@data]
      end
      alias to_h to_hash

      def to_json
        to_hash.to_json
      end

      def to_array
        @data
      end
      alias to_a to_array

    end
  end
end

