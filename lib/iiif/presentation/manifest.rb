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

      def tidy_arrays
        ARRAY_KEYS.each do |k|
          if self.has_key?(k)
            if self[k].empty?
              self.delete(k)
            else
              unless self[k].all? { |entry| entry.kind_of?(Hash) }
                raise TypeError, "All entries in the #{k} list must be a type of Hash"
              end
            end
          end
        end
        super()
      end

    end
  end
end




