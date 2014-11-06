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

      def required_keys
        super + %w{ @id label }
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

      OPTIONAL_KEYS = %w{ viewing_direction }
      # would be nice to be able to hand this array to a reusable method
      # See: http://ruby-doc.org/core-2.0.0/Object.html#method-i-define_singleton_method
      # (from http://ruby-doc.org/core-2.0.0/Object.html#method-i-define_singleton_method)
      OPTIONAL_KEYS.each do |anywhere_prop|
        # Setters
        define_method("#{anywhere_prop}=") do |arg|
          self.send('[]=', "#{anywhere_prop}", arg)
        end
        if anywhere_prop.camelize(:lower) != anywhere_prop
          define_method("#{anywhere_prop.camelize(:lower)}=") do |arg|
            self.send('[]=', "#{anywhere_prop}", arg)
          end
        end
        # Getters
        define_method("#{anywhere_prop}") do
          self.send('[]', "#{anywhere_prop}")
        end
        if anywhere_prop.camelize(:lower) != anywhere_prop
          define_method(anywhere_prop.camelize(:lower)) do
            self.send('[]', "#{anywhere_prop}")
          end
        end
      end
    end
  end
end
