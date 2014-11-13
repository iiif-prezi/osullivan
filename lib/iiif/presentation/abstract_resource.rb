require File.join(File.dirname(__FILE__), 'hash_behaviours')
require File.join(File.dirname(__FILE__), '../../active_support/ordered_hash')
require 'active_support/ordered_hash'
require 'active_support/inflector'
require 'json'

module IIIF
  module Presentation
    class AbstractResource

      include IIIF::Presentation::HashBehaviours
      # include IIIF::Presentation::UpdateBehaviours

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
        self.snakeize_keys
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

      # Options
      #  * pretty: (true|false). Should the JSON be pretty-printed? (default: false)
      #  * All options available in #to_ordered_hash
      def to_json(opts={})
        # could add context here, after the hash is made
        hsh = self.to_ordered_hash(opts)
        if opts.fetch(:pretty, false)
          JSON.pretty_generate(hsh)
        else
          hsh.to_json
        end
      end

      # Options:
      #  * force: (true|false). Skips validations. 
      #  * include_context: (true|false). Adds the @context to the top of the
      #      document if it doesn't exist. Default: true.
      #  * sort_json_ld_keys: (true|false). Brings all properties starting with 
      #      '@'. Default: true. to the top of the document and sorts them.
      def to_ordered_hash(opts={})
        force = opts.fetch(:force, false)
        include_context = opts.fetch(:include_context, true)
        sort_json_ld_keys = opts.fetch(:sort_json_ld_keys, true)

        unless force
          self.validate
        end

        if include_context && !self.has_key?('@context')
          self['@context'] = IIIF::Presentation::CONTEXT
        end

        export_hash = ActiveSupport::OrderedHash.new

        if sort_json_ld_keys
          self.keys.select { |k| k.start_with?('@') }.sort!.each do |k|
            export_hash[k] = self.data[k]
          end
        end

        self.keys.each do |k|
          unless sort_json_ld_keys && k.start_with?('@')
            if self[k].respond_to?(:to_ordered_hash)
              opts = {
                include_context: false,
                sort_json_ld_keys: sort_json_ld_keys,
                force: force
              }
              export_hash[k] = self.data[k].to_ordered_hash(opts)
            else
              export_hash[k] = self.data[k]
            end
          end
        end
        export_hash.remove_empties
        export_hash.camelize_keys
        export_hash
      end

      protected
      def data=(hsh)
        @data = hsh
      end

      def data
        @data
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
