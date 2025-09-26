require File.join(File.dirname(__FILE__), 'hash_behaviours')
require 'active_support/core_ext/class/subclasses'
require 'active_support/ordered_hash'
require 'active_support/inflector'
require 'json'

module IIIF
  class Service
    include IIIF::HashBehaviours

    # Anything goes! SHOULD have @id and profile, MAY have label
    # Consider subclassing this for typical services...
    def required_keys
      %w[]
    end

    def any_type_keys
      %w[]
    end

    def string_only_keys
      %w[]
    end

    def array_only_keys
      %w[]
    end

    def abstract_resource_only_keys
      %w[]
    end

    def hash_only_keys
      %w[]
    end

    def int_only_keys
      %w[]
    end

    def numeric_only_keys
      %w[]
    end

    def initialize(hsh = {})
      @data = IIIF::OrderedHash[hsh]
      define_methods_for_any_type_keys
      define_methods_for_array_only_keys
      define_methods_for_string_only_keys
      define_methods_for_int_only_keys
      define_methods_for_numeric_only_keys
      define_methods_for_abstract_resource_only_keys
      snakeize_keys
    end

    # Static methods / alternative constructors
    class << self
      # Parse from a file path, string, or existing hash
      def parse(s)
        ordered_hash = nil
        if s.is_a?(String) && File.exist?(s)
          ordered_hash = IIIF::OrderedHash[JSON.parse(IO.read(s))]
        elsif s.is_a?(String) && !File.exist?(s)
          ordered_hash = IIIF::OrderedHash[JSON.parse(s)]
        elsif s.is_a?(Hash)
          ordered_hash = IIIF::OrderedHash[s]
        else
          m = '#parse takes a path to a file, a JSON String, or a Hash, '
          m += "argument was a #{s.class}."
          m += "If you were trying to point to a file, does it exist?" if s.is_a?(String)
          raise ArgumentError, m
        end
        IIIF::Service.from_ordered_hash(ordered_hash)
      end
    end

    def validate
      # TODO:
      # * check for required keys
      # * type check Array-only values
      # * type check String-only values
      # * type check Integer-only values
      # * type check AbstractResource-only values
      required_keys.each do |k|
        unless has_key?(k)
          m = "A(n) #{k} is required for each #{self.class}"
          raise IIIF::Presentation::MissingRequiredKeyError, m
        end
      end
      # Viewing Direction values
      if has_key?('viewing_direction') && !legal_viewing_direction_values.include?(self['viewing_direction'])
        m = "viewingDirection must be one of #{legal_viewing_direction_values}"
        raise IIIF::Presentation::IllegalValueError, m
      end
      # Viewing Hint values
      if has_key?('viewing_hint') && !legal_viewing_hint_values.include?(self['viewing_hint'])
        m = "viewingHint for #{self.class} must be one of #{legal_viewing_hint_values}."
        raise IIIF::Presentation::IllegalValueError, m
      end
      # Metadata is all hashes
      return unless has_key?('metadata')
      return if self['metadata'].all? { |entry| entry.is_a?(Hash) }

      m = 'All entries in the metadata list must be a type of Hash'
      raise IIIF::Presentation::IllegalValueError, m
    end

    # Options
    #  * pretty: (true|false). Should the JSON be pretty-printed? (default: false)
    #  * All options available in #to_ordered_hash
    def to_json(opts = {})
      hsh = to_ordered_hash(opts)
      if opts.fetch(:pretty, false)
        JSON.pretty_generate(hsh)
      else
        hsh.to_json
      end
    end

    # Options:
    #  * force: (true|false). Skips validations.
    #  * sort_json_ld_keys: (true|false). Brings all properties starting with
    #      '@'. Default: true. to the top of the document and sorts them.
    def to_ordered_hash(opts = {})
      force = opts.fetch(:force, false)
      sort_json_ld_keys = opts.fetch(:sort_json_ld_keys, true)

      validate unless force

      export_hash = IIIF::OrderedHash.new

      if sort_json_ld_keys
        keys.select { |k| k.start_with?('@') }.sort!.each do |k|
          export_hash[k] = data[k]
        end
      end

      sub_opts = {
        include_context: false,
        sort_json_ld_keys: sort_json_ld_keys,
        force: force
      }
      keys.each do |k|
        unless sort_json_ld_keys && k.start_with?('@')
          if data[k].respond_to?(:to_ordered_hash) # .respond_to?(:to_ordered_hash)
            export_hash[k] = data[k].to_ordered_hash(sub_opts)

          elsif data[k].is_a?(Hash)
            export_hash[k] = IIIF::OrderedHash.new
            data[k].each do |sub_k, v|
              if v.respond_to?(:to_ordered_hash)
                export_hash[k][sub_k] = v.to_ordered_hash(sub_opts)

              elsif v.is_a?(Array)
                export_hash[k][sub_k] = []
                v.each do |member|
                  export_hash[k][sub_k] << if member.respond_to?(:to_ordered_hash)
                                             member.to_ordered_hash(sub_opts)
                                           else
                                             member
                                           end
                end
              else
                export_hash[k][sub_k] = v
              end
            end

          elsif data[k].is_a?(Array)
            export_hash[k] = []

            data[k].each do |member|
              if member.respond_to?(:to_ordered_hash)
                export_hash[k] << member.to_ordered_hash(sub_opts)

              elsif member.is_a?(Hash)
                hsh = IIIF::OrderedHash.new
                export_hash[k] << hsh
                member.each do |sub_k, v|
                  if v.respond_to?(:to_ordered_hash)
                    hsh[sub_k] = v.to_ordered_hash(sub_opts)

                  elsif v.is_a?(Array)
                    hsh[sub_k] = []

                    v.each do |sub_member|
                      hsh[sub_k] << if sub_member.respond_to?(:to_ordered_hash)
                                      sub_member.to_ordered_hash(sub_opts)
                                    else
                                      sub_member
                                    end
                    end
                  else
                    hsh[sub_k] = v
                  end
                end

              else
                export_hash[k] << member
                # there are no nested arrays, right?
              end
            end
          else
            export_hash[k] = data[k]
          end

        end
      end
      export_hash.remove_empties
      export_hash.camelize_keys
      export_hash
    end

    def self.from_ordered_hash(hsh, default_klass = IIIF::OrderedHash)
      # Create a new object (new_object)
      type = nil
      type = IIIF::Service.get_descendant_class_by_jld_type(hsh['@type']) if hsh.has_key?('@type')
      new_object = type.nil? ? default_klass.new : type.new

      hsh.keys.each do |key|
        new_key = key.underscore == key ? key : key.underscore
        if hsh[key].is_a?(Array)
          new_object[new_key] = []
          hsh[key].each do |member|
            new_object[new_key] << if new_key == 'service'
                                     IIIF::Service.from_ordered_hash(member, IIIF::Presentation::Service)
                                   elsif new_key == 'resource'
                                     IIIF::Service.from_ordered_hash(hsh[key], IIIF::Presentation::Resource)
                                   elsif member.is_a?(Hash)
                                     IIIF::Service.from_ordered_hash(member)
                                   else
                                     member
                                     # Again, no nested arrays, right?
                                   end
          end
        elsif new_key == 'service'
          new_object[new_key] = IIIF::Service.from_ordered_hash(hsh[key], IIIF::Presentation::Service)
        elsif new_key == 'resource'
          new_object[new_key] = IIIF::Service.from_ordered_hash(hsh[key], IIIF::Presentation::Resource)
        elsif hsh[key].is_a?(Hash)
          new_object[new_key] = IIIF::Service.from_ordered_hash(hsh[key])
        else
          new_object[new_key] = hsh[key]
        end
      end
      new_object
    end

    protected

    def self.get_descendant_class_by_jld_type(type)
      IIIF::Service.all_service_subclasses.find do |klass|
        klass.const_defined?(:TYPE) && klass.const_get(:TYPE) == type
      end
    end

    # All known subclasses of service.
    def self.all_service_subclasses
      @all_service_subclasses ||= IIIF::Service.descendants.reject(&:singleton_class?)
    end

    attr_accessor :data

    def define_methods_for_any_type_keys
      define_accessor_methods(*any_type_keys)

      # override the getter defined by define_accessor_methods to avoid returning
      # an array for empty values.
      any_type_keys.each do |key|
        define_singleton_method(key) do
          send('[]', key)
        end
      end
    end

    def define_methods_for_array_only_keys
      define_accessor_methods(*array_only_keys) do |key, arg|
        unless arg.is_a?(Array)
          m = "#{key} must be an Array."
          raise IIIF::Presentation::IllegalValueError, m
        end
      end
    end

    def define_methods_for_abstract_resource_only_keys
      # keys in this case is an array of hashes with { key: 'k', type: Class }
      abstract_resource_only_keys.each do |hsh|
        key = hsh[:key]
        type = hsh[:type]

        define_accessor_methods(key) do |key, arg|
          unless arg.is_a?(type)
            m = "#{key} must be an #{type}."
            raise IIIF::Presentation::IllegalValueError, m
          end
        end
      end
    end

    def define_methods_for_string_only_keys
      define_accessor_methods(*string_only_keys) do |key, arg|
        unless arg.is_a?(String)
          m = "#{key} must be an String."
          raise IIIF::Presentation::IllegalValueError, m
        end
      end
    end

    def define_methods_for_int_only_keys
      define_accessor_methods(*int_only_keys) do |key, arg|
        unless arg.is_a?(Integer) && arg > 0
          m = "#{key} must be a positive Integer."
          raise IIIF::Presentation::IllegalValueError, m
        end
      end
    end

    def define_methods_for_numeric_only_keys
      define_accessor_methods(*numeric_only_keys) do |key, arg|
        unless arg.is_a?(Numeric) && arg > 0
          m = "#{key} must be a positive Integer or Float."
          raise IIIF::Presentation::IllegalValueError, m
        end
      end
    end

    def define_accessor_methods(*keys, &validation)
      keys.each do |key|
        # Setter
        define_singleton_method("#{key}=") do |arg|
          validation.call(key, arg) if block_given?
          send('[]=', key, arg)
        end
        if key.camelize(:lower) != key
          define_singleton_method("#{key.camelize(:lower)}=") do |arg|
            validation.call(key, arg) if block_given?
            send('[]=', key, arg)
          end
        end
        # Getter
        define_singleton_method(key) do
          self[key] ||= []
          self[key]
        end
        next unless key.camelize(:lower) != key

        define_singleton_method(key.camelize(:lower)) do
          send('[]', key)
        end
      end
    end
  end
end
