require File.join(File.dirname(__FILE__), 'hash_behaviours')
require File.join(File.dirname(__FILE__), 'update_behaviours')
require 'active_support/ordered_hash'
require 'active_support/inflector'
require 'json'

module IIIF
  module Presentation
    class AbstractObject

      include IIIF::Presentation::HashBehaviours
      include IIIF::Presentation::UpdateBehaviours

      CONTEXT ||= 'http://iiif.io/api/presentation/2/context.json'

      # Every subclass should override this, see Manifest for how.
      def required_keys
        %w{ @type }
      end

      def optional_keys
        %w{ label description thumbnail attribution license logo see_also 
          service related within }
      end

      def array_only_keys
        %w{ metadata }
      end

      def string_only_keys
        %w{ viewing_hint } # should any of the optional keys be here?
      end

      # Initialize a Presentation node
      # @param [Hash] hsh - Anything in this hash will be added to the Object.'
      #   Order is only guaranteed if an ActiveSupport::OrderedHash is passed.
      # @param [boolean] include_context (default: false). Pass true if the'
      #   context should be included.
      def initialize(hsh={}, include_context=false)
        @data = ActiveSupport::OrderedHash[hsh]
        unless hsh.has_key?('@context') || !include_context
          self.insert(0, '@context', CONTEXT)
        end
        if self.class == IIIF::Presentation::AbstractObject
          raise "#{self.class} is an abstract class. Please use one of its subclasses."
        end
        self.define_methods_for_keys(self.optional_keys)
        self.define_methods_for_array_only_keys(self.array_only_keys)
        self.define_methods_for_string_only_keys(self.string_only_keys)
      end

      # Static methods and alternative constructors
      class << self
        # Parse from a file path, string, or existing hash
        def parse(s)
          new_instance = new()
          if s.kind_of?(String) && File.exists?(s)
            new_instance.data = JSON.parse(IO.read(s))
          elsif s.kind_of?(String) && !File.exists?(s)
            new_instance.data = JSON.parse(s)
          elsif s.kind_of?(Hash)
            new_instance.data = ActiveSupport::OrderedHash[s]
          else
            m = '#parse takes a path to a file, a JSON String, or a Hash, '
            m += "argument was a #{s.class}."
            if s.kind_of?(String)
              m+= "If you were trying to point to a file, does it exist?"
            end
            raise ArgumentError, m
          end
          new_instance
        end
      end

      def to_hash
        self.tidy_empties
        self.validate
        @data
      end
      alias to_h to_hash

      def to_json
        self.to_hash.to_json
      end

      def to_pretty_json
        JSON.pretty_generate(self.to_hash)
      end

      def tidy_empties
        # metadata TODO: cover all that must be arrays here
        if self.has_key?('metadata')
          if self['metadata'].empty?
            self.delete('metadata')
          else
            unless self['metadata'].all? { |entry| entry.kind_of?(Hash) }
              raise TypeError, 'All entries in the metadata list must be a type of Hash'
            end
          end
        end
      end

      def validate
        self.required_keys.each do |k|
          unless self.has_key?(k)
            raise MissingRequiredKeyError, "A(n) #{k} is required for each #{self.class}"
          end
        end
      end

      # TODO get these protected
      def data=(hsh)
        @data = hsh
      end

      def data
        @data
      end

      protected
      def define_methods_for_keys(keys)
        keys.each do |key|
          # Setters
          define_singleton_method("#{key}=") do |arg|
            self.send('[]=', "#{key}", arg)
          end
          if key.camelize(:lower) != key
            define_singleton_method("#{key.camelize(:lower)}=") do |arg|
              self.send('[]=', "#{key}", arg)
            end
          end
          # Getters
          define_singleton_method("#{key}") do
            self.send('[]', "#{key}")
          end
          if key.camelize(:lower) != key
            define_singleton_method(key.camelize(:lower)) do
              self.send('[]', "#{key}")
            end
          end
        end
      end

      def define_methods_for_array_only_keys(keys)
        keys.each do |key|
          # Setter
          define_singleton_method("#{key}=") do |arg|
            unless arg.kind_of?(Array)
              raise TypeError, "#{key} must be an Array."
            end
            self.send('[]=', key, arg)
          end
          # Getter
          define_singleton_method(key) do
            self[key] ||= []
            self[key]
          end
        end
      end

      def define_methods_for_string_only_keys(keys)
        keys.each do |key|
          # Setter
          define_singleton_method("#{key}=") do |arg|
            unless arg.kind_of?(String)
              raise TypeError, "#{key} must be an String."
            end
            self.send('[]=', key, arg)
          end
          # Getter
          define_singleton_method(key) do
            self[key] ||= []
            self[key]
          end
        end
      end

    end

    class MissingRequiredKeyError < StandardError; end

  end
end

