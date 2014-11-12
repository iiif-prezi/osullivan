require File.join(File.dirname(__FILE__), 'hash_behaviours')
require File.join(File.dirname(__FILE__), 'update_behaviours')
require 'active_support/ordered_hash'
require 'active_support/inflector'
require 'json'

module IIIF
  module Presentation
    class AbstractResource

      include IIIF::Presentation::HashBehaviours
      include IIIF::Presentation::UpdateBehaviours

      # Every subclass should override the following five methods where 
      # appropriate, see Subclasses for how.
      def required_keys
        %w{ @type }
      end

      def any_type_keys # these are allowed on all classes
        %w{ label description thumbnail attribution license logo see_also
        service related within }
      end

      def array_only_keys
        %w{ metadata }
      end

      def string_only_keys
        %w{ viewing_hint } # should any of the any type keys be here?
      end

      def int_only_keys
        %w{ }
      end

      # Not every subclass is allowed to have viewingDirect, but when it is,
      # it must be one of these values
      def legal_viewing_direction_values
        %w{ left-to-right right-to-left top-to-bottom bottom-to-top }
      end

      # Initialize a Presentation node
      # @param [Hash] hsh - Anything in this hash will be added to the Object.'
      #   Order is only guaranteed if an ActiveSupport::OrderedHash is passed.
      # @param [boolean] include_context (default: false). Pass true if the'
      #   context should be included.
      def initialize(hsh={}, include_context=false)
        @data = ActiveSupport::OrderedHash[hsh]
        unless hsh.has_key?('@context') || !include_context
          self.unshift('@context', IIIF::Presentation::CONTEXT)
        end
        if self.class == IIIF::Presentation::AbstractResource
          raise "#{self.class} is an abstract class. Please use one of its subclasses."
        end
        self.define_methods_for_any_type_keys(self.any_type_keys)
        self.define_methods_for_array_only_keys(self.array_only_keys)
        self.define_methods_for_string_only_keys(self.string_only_keys)
        self.define_methods_for_int_only_keys(self.int_only_keys)
        self.un_camel
      end

      # Static methods and alternative constructors
      class << self
        # Parse from a file path, string, or existing hash
        def parse(s)
          if s.kind_of?(String) && File.exists?(s)
            return new(JSON.parse(IO.read(s)))
          elsif s.kind_of?(String) && !File.exists?(s)
            return new(JSON.parse(s))
          elsif s.kind_of?(Hash)
            return new(ActiveSupport::OrderedHash[s])
          else
            m = '#parse takes a path to a file, a JSON String, or a Hash, '
            m += "argument was a #{s.class}."
            if s.kind_of?(String)
              m+= "If you were trying to point to a file, does it exist?"
            end
            raise ArgumentError, m
          end
        end
      end

      def to_hash
        # TODO: go all out and really override this (not just return @data)
        # In the process:
        #  * insert the context (recursive calls should take include_context: false)
        #  * get all of the json-ld properties up to the top
        #  * take a `force: true|false` argument for skipping validatoins
        #  * not return something that is a part of the object, but a new OrderedHash instance
        #  * to_json and to_pretty_json should take the same options
        #     * maybe to_json should also just take pretty: true|false?
        #
        # Use self.keys
        #
        # Will need to check for respond_to?(to_ordered_hash) (RENAME THE METHOD)
        # otherwise just copy Strings, Arrays, and Integers over
        #    
        self.tidy_empties
        self.validate
        self.un_snake
        @data
      end

      def to_json
        # could add context here, after the hash is made
        self.to_hash.to_json
      end

      def to_pretty_json
        JSON.pretty_generate(self.to_hash)
      end

      def validate
        # TODO:
        # * type check Array-only values
        # * type check String-only values
        # * type check Integer-only values

        # Required keys
        self.required_keys.each do |k|
          unless self.has_key?(k)
            m = "A(n) #{k} is required for each #{self.class}"
            raise IIIF::Presentation::MissingRequiredKeyError, m
          end
        end
        # Viewing Direction values
        if self.has_key?('viewing_direction')
          unless self.legal_viewing_direction_values.include?(self['viewing_direction'])
            m = "viewingDirection must be one of #{legal_viewing_direction_values}"
            raise IIIF::Presentation::IllegalValueError, m
          end
        end
        # Viewing Hint values
        if self.has_key?('viewing_hint')
          unless self.legal_viewing_hint_values.include?(self['viewing_hint'])
            m = "viewingHint for #{self.class} must be one of #{self.legal_viewing_hint_values}."
            raise IIIF::Presentation::IllegalValueError, m
          end
        end
        # Metadata is all hashes
        if self.has_key?('metadata')
          unless self['metadata'].all? { |entry| entry.kind_of?(Hash) }
            m = 'All entries in the metadata list must be a type of Hash'
            raise IIIF::Presentation::IllegalValueError, m
          end
        end
      end


      protected

      def data=(hsh)
        @data = hsh
      end

      def data
        @data
      end

      def tidy_empties
        # * Delete any keys that are empty arrays
        self.keys.each do |key|
          if self[key].kind_of?(Array) && self[key].empty?
            self.delete(key)
          end
        end

        # TODO:
        #  * Where possible (i.e. for properties that aren't required to be
        #    Arrays) make keys that reference one-member arrays reference that
        #    the array memebr directly (e.g. foo => [bar] becomes foo => bar)

      end

      def un_snake
        self.keys.each_with_index do |key, i|
          if key != key.camelize(:lower)
            self.insert(i, key.camelize(:lower), self[key])
            self.delete(key)
          end
        end
        self
      end

      # Static since this intended to be used in contructors only (and we 
      # can't protect it).
      def un_camel
        self.keys.each_with_index do |key, i|
          if key != key.underscore
            self.insert(i, key.underscore, self[key])
            self.delete(key)
          end
        end
        self
      end

      def define_methods_for_any_type_keys(keys)
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
              m = "#{key} must be an Array."
              raise IIIF::Presentation::IllegalValueError, m
            end
            self.send('[]=', key, arg)
          end
          if key.camelize(:lower) != key
            define_singleton_method("#{key.camelize(:lower)}=") do |arg|
              unless arg.kind_of?(Array)
                m = "#{key} must be an Array."
                raise IIIF::Presentation::IllegalValueError, m
              end
              self.send('[]=', "#{key}", arg)
            end
          end
          # Getter
          define_singleton_method(key) do
            self[key] ||= []
            self[key]
          end
          if key.camelize(:lower) != key
            define_singleton_method(key.camelize(:lower)) do
              self.send('[]', "#{key}")
            end
          end
        end
      end

      def define_methods_for_string_only_keys(keys)
        keys.each do |key|
          # Setter
          define_singleton_method("#{key}=") do |arg|
            unless arg.kind_of?(String)
              m = "#{key} must be an String."
              raise IIIF::Presentation::IllegalValueError, m
            end
            self.send('[]=', key, arg)
          end
          if key.camelize(:lower) != key
            define_singleton_method("#{key.camelize(:lower)}=") do |arg|
              unless arg.kind_of?(String)
                m = "#{key} must be an String."
                raise IIIF::Presentation::IllegalValueError, m
              end
              self.send('[]=', "#{key}", arg)
            end
          end
          # Getter
          define_singleton_method(key) do
            self[key] ||= []
            self[key]
          end
          if key.camelize(:lower) != key
            define_singleton_method(key.camelize(:lower)) do
              self.send('[]', "#{key}")
            end
          end
        end
      end

      def define_methods_for_int_only_keys(keys)
        keys.each do |key|
          # Setter
          define_singleton_method("#{key}=") do |arg|
            unless arg.kind_of?(Integer) && arg > 0
              m = "#{key} must be a positive Integer."
              raise IIIF::Presentation::IllegalValueError, m
            end
            self.send('[]=', key, arg)
          end
          if key.camelize(:lower) != key
            define_singleton_method("#{key.camelize(:lower)}=") do |arg|
              unless arg.kind_of?(Integer) && arg > 0
                m = "#{key} must be a positive Integer."
                raise IIIF::Presentation::IllegalValueError, m
              end
              self.send('[]=', "#{key}", arg)
            end
          end
          # Getter
          define_singleton_method(key) do
            self[key] ||= []
            self[key]
          end
          if key.camelize(:lower) != key
            define_singleton_method(key.camelize(:lower)) do
              self.send('[]', "#{key}")
            end
          end
        end
      end

    end

  end
end
