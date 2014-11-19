require File.join(File.dirname(__FILE__), 'abstract_resource')

module IIIF
  module Presentation
    class Resource < AbstractResource

      def required_keys
        %w{ @id } # no @type strictly required, so no super
      end

      def string_only_keys
        super + %w{ format }
      end

      def initialize(hsh={})
        
        hsh['motivation'] = 'sc:painting' unless hsh.has_key? 'motivation'
        super(hsh)
      end

    end
  end
end
