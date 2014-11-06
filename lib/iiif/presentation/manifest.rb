# Doing this to make Travis happy. It seems to not always find everything if
# the tests run in the wrong order
Dir["#{File.dirname(__FILE__)}/*.rb"].each do |f|
  require f
end

module IIIF
  module Presentation
    class Manifest < AbstractObject

      def initialize(hsh={})
        # make it possible to subclass manifest, possibly with a different @type
        hsh['@type'] = 'sc:Manifest' unless hsh.has_key? '@type'
        super(hsh)
      end

      ARRAY_KEYS = %w{sequences structures}
      ARRAY_KEYS.each do |k|
        define_method("#{k}=") do |arg|
          unless arg.kind_of?(Array)
            raise TypeError, "#{prop} must be an Array."
          end
          self.send('[]=', k, arg)
        end
        define_method(k) do
          self[k] ||= []
          self[k]
        end
      end

    end
  end
end
