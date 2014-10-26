
require File.join(File.dirname(__FILE__), 'node')
require File.join(File.dirname(__FILE__), 'hash_behaviours')

module IIIF
  module Presentation
    class Manifest < Node
      include IIIF::Presentation::HashBehaviours

      def initialize(hsh={})
        super('sc:Manifest', hsh)
      end

    end
  end
end



