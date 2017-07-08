require_relative '../hash_behaviours'

module IIIF
  module V3
    class AbstractResource
      include IIIF::HashBehaviours

      # properties used by content resources only
      CONTENT_RESOURCE_PROPERTIES = %w{ format height width duration }

      # used by Collection, AnnotationCollection
      PAGING_PROPERTIES = %w{ first last next prev total start_index }

      # subclasses should override required_keys as appropriate, e.g. super + %w{ id }
      def required_keys
        %w{ type }
      end

      # subclasses should override prohibited_keys as appropriate, e.g. super + PAGING_PROPERTIES
      def prohibited_keys
        %w{ }
      end

      # NOTE: keys associated with a single resource type are not included below in xxx_keys methods:
      #  those single resource types should include additional keys by overriding xxx_keys as appropriate

      def any_type_keys
        # values *may* be multivalued
        # NOTE: for id: "Resources that do not require URIs [for ids] may be assigned blank node identifiers"
        %w{ label description id attribution logo related rendering see_also within }
      end

      def string_only_keys
        %w{ nav_date type format viewing_direction viewing_hint start_canvas }
      end

      def array_only_keys
        %w{ metadata rights thumbnail first last next prev items }
      end

      def abstract_resource_only_keys
        [ { key: 'service', type: IIIF::V3::Presentation::Service } ]
      end

      def hash_only_keys
        %w{ }
      end

      def int_only_keys
        %w{ height width total start_index }
      end

      def numeric_only_keys
        %w{ duration }
      end

      def uri_only_keys
        %w{ }
      end

      # Not every subclass is allowed to have viewingDirect, but when it is,
      # it must be one of these values
      def legal_viewing_direction_values
        %w{ left-to-right right-to-left top-to-bottom bottom-to-top }
      end

      def legal_viewing_hint_values
        []
      end

      # Initialize a Presentation node
      # @param [Hash] hsh - Anything in this hash will be added to the Object.
      #   Order is only guaranteed if an ActiveSupport::OrderedHash is passed.
      # @param [boolean] include_context (default: false). Pass true if the
      #   context should be included.
      def initialize(hsh={})
        if self.class == IIIF::V3::AbstractResource
          raise "#{self.class} is an abstract class. Please use one of its subclasses."
        end
        @data = IIIF::OrderedHash[hsh]
        self.define_methods_for_any_type_keys
        self.define_methods_for_string_only_keys
        self.define_methods_for_array_only_keys
        self.define_methods_for_hash_only_keys
        self.define_methods_for_int_only_keys
        self.define_methods_for_numeric_only_keys
        self.define_methods_for_abstract_resource_only_keys
        self.define_methods_for_uri_only_keys
        self.snakeize_keys
      end

      # Static methods / alternative constructors
      class << self
        # Parse from a file path, string, or existing hash
        def parse(s)
          ordered_hash = nil
          if s.kind_of?(String) && File.exists?(s)
            ordered_hash = IIIF::OrderedHash[JSON.parse(IO.read(s))]
          elsif s.kind_of?(String) && !File.exists?(s)
            ordered_hash = IIIF::OrderedHash[JSON.parse(s)]
          elsif s.kind_of?(Hash)
            ordered_hash = IIIF::OrderedHash[s]
          else
            m = '#parse takes a path to a file, a JSON String, or a Hash, '
            m += "argument was a #{s.class}."
            if s.kind_of?(String)
              m+= "If you were trying to point to a file, does it exist?"
            end
            raise ArgumentError, m
          end
          return IIIF::V3::Presentation::Service.from_ordered_hash(ordered_hash)
        end
      end

      def validate
        self.required_keys.each do |k|
          unless self.has_key?(k)
            m = "A(n) #{k} is required for each #{self.class}"
            raise IIIF::V3::Presentation::MissingRequiredKeyError, m
          end
        end

        self.prohibited_keys.each do |k|
          if self.has_key?(k)
            m = "#{k} is a prohibited key in #{self.class}"
            raise IIIF::V3::Presentation::ProhibitedKeyError, m
          end
        end

        # Note:  self.define_methods_for_xxx_only_keys does NOT provide validation
        #  when key values are assigned directly with hash syntax, e.g. my_image_resource['format']= 'image/jpeg'

        # Viewing Direction values
        if self.has_key?('viewing_direction')
          unless self.legal_viewing_direction_values.include?(self['viewing_direction'])
            m = "viewingDirection must be one of #{legal_viewing_direction_values}"
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
        # Viewing Hint values
        if self.has_key?('viewing_hint')
          unless self.legal_viewing_hint_values.include?(self['viewing_hint'])
            m = "viewingHint for #{self.class} must be one of #{self.legal_viewing_hint_values}"
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
        # Metadata is Array; each entry is a Hash containing (only) 'label' and 'value' properties
        if self.has_key?('metadata') && self['metadata']
          unless self['metadata'].all? { |entry| entry.kind_of?(Hash) }
            m = 'metadata must be an Array with Hash members'
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
          self['metadata'].each do |entry|
            md_keys = entry.keys
            unless md_keys.size == 2 && md_keys.include?('label') && md_keys.include?('value')
              m = "metadata members must be a Hash of keys 'label' and 'value'"
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end
        # Thumbnail is Array; each entry is a Hash containing (at least) 'id' and 'type' keys
        if self.has_key?('thumbnail') && self['thumbnail']
          unless self['thumbnail'].all? { |entry| entry.kind_of?(Hash) }
            m = 'thumbnail must be an Array with Hash members'
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
          self['thumbnail'].each do |entry|
            thumb_keys = entry.keys
            unless thumb_keys.include?('id') && thumb_keys.include?('type')
              m = 'thumbnail members must be a Hash including keys "id" and "type"'
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end
        # NavDate (navigation date)
        if self.has_key?('nav_date')
          begin
            Date.strptime(self['nav_date'], '%Y-%m-%dT%H:%M:%SZ')
          rescue ArgumentError
            m = "nav_date must be of form YYYY-MM-DDThh:mm:ssZ"
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end

        # TODO: rights - confusing;  Array of hashes? including id which must be a URI?
        # rights

        # TODO: rendering -  A label and the format of the rendering resource must be supplied
      end

      # Options
      #  * pretty: (true|false). Should the JSON be pretty-printed? (default: false)
      #  * All options available in #to_ordered_hash
      def to_json(opts={})
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
        include_context = opts.fetch(:include_context, true)
        if include_context && !self.has_key?('@context')
          self['@context'] = IIIF::V3::Presentation::CONTEXT
        end
        force = opts.fetch(:force, false)
        sort_json_ld_keys = opts.fetch(:sort_json_ld_keys, true)

        unless force
          self.validate
        end

        export_hash = IIIF::OrderedHash.new

        if sort_json_ld_keys
          self.keys.select { |k| k.start_with?('@') }.sort!.each do |k|
            export_hash[k] = self.data[k]
          end
        end

        sub_opts = {
          include_context: false,
          sort_json_ld_keys: sort_json_ld_keys,
          force: force
        }
        self.keys.each do |k|
          unless sort_json_ld_keys && k.start_with?('@')
            if self.data[k].respond_to?(:to_ordered_hash) #.respond_to?(:to_ordered_hash)
              export_hash[k] = self.data[k].to_ordered_hash(sub_opts)

            elsif self.data[k].kind_of?(Hash)
              export_hash[k] = IIIF::OrderedHash.new
              self.data[k].each do |sub_k, v|

                if v.respond_to?(:to_ordered_hash)
                  export_hash[k][sub_k] = v.to_ordered_hash(sub_opts)

                elsif v.kind_of?(Array)
                  export_hash[k][sub_k] = []
                  v.each do |member|
                    if member.respond_to?(:to_ordered_hash)
                      export_hash[k][sub_k] << member.to_ordered_hash(sub_opts)
                    else
                      export_hash[k][sub_k] << member
                    end
                  end
                else
                  export_hash[k][sub_k] = v
                end
              end

            elsif self.data[k].kind_of?(Array)
              export_hash[k] = []

              self.data[k].each do |member|
                if member.respond_to?(:to_ordered_hash)
                  export_hash[k] << member.to_ordered_hash(sub_opts)

                elsif member.kind_of?(Hash)
                  hsh = IIIF::OrderedHash.new
                  export_hash[k] << hsh
                  member.each do |sub_k,v|

                    if v.respond_to?(:to_ordered_hash)
                      hsh[sub_k] = v.to_ordered_hash(sub_opts)

                    elsif v.kind_of?(Array)
                      hsh[sub_k] = []

                      v.each do |sub_member|
                        if sub_member.respond_to?(:to_ordered_hash)
                          hsh[sub_k] << sub_member.to_ordered_hash(sub_opts)
                        else
                          hsh[sub_k] << sub_member
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
              export_hash[k] = self.data[k]
            end

          end
        end
        export_hash.remove_empties
        export_hash.camelize_keys
        export_hash
      end

      def self.from_ordered_hash(hsh, default_klass=IIIF::OrderedHash)
        # Create a new object (new_object)
        type = nil
        if hsh.has_key?('type')
          type = IIIF::V3::AbstractResource.get_descendant_class_by_jld_type(hsh['type'])
        end
        new_object = type.nil? ? default_klass.new : type.new

        hsh.keys.each do |key|
          new_key = key.underscore == key ? key : key.underscore
          if new_key == 'service'
            new_object[new_key] = IIIF::V3::AbstractResource.from_ordered_hash(hsh[key], IIIF::V3::Presentation::Service)
          elsif new_key == 'body'
            new_object[new_key] = IIIF::V3::AbstractResource.from_ordered_hash(hsh[key], IIIF::V3::Presentation::Resource)
          elsif hsh[key].kind_of?(Hash)
            new_object[new_key] = IIIF::V3::AbstractResource.from_ordered_hash(hsh[key])
          elsif hsh[key].kind_of?(Array)
            new_object[new_key] = []
            hsh[key].each do |member|
              if new_key == 'service'
                new_object[new_key] << IIIF::V3::AbstractResource.from_ordered_hash(member, IIIF::V3::Presentation::Service)
              elsif member.kind_of?(Hash)
                new_object[new_key] << IIIF::V3::AbstractResource.from_ordered_hash(member)
              else
                new_object[new_key] << member
                # Again, no nested arrays, right?
              end
            end
          else
            new_object[new_key] = hsh[key]
          end
        end
        new_object
      end

      protected

      def self.get_descendant_class_by_jld_type(type)
        IIIF::V3::AbstractResource.all_known_subclasses.find do |klass|
          klass.const_defined?(:TYPE) && klass.const_get(:TYPE) == type
        end
      end

      def self.all_known_subclasses
        @all_known_subclasses ||= IIIF::V3::AbstractResource.descendants.reject(&:singleton_class?)
      end

      def data=(hsh)
        @data = hsh
      end

      def data
        @data
      end

      def define_methods_for_any_type_keys
        define_accessor_methods(*any_type_keys)

        # override the getter defined by define_accessor_methods to avoid returning
        # an array for empty values.
        any_type_keys.each do |key|
          define_singleton_method(key) do
            self.send('[]', key)
          end
        end
      end

      def define_methods_for_array_only_keys
        define_accessor_methods(*array_only_keys) do |key, val|
          unless val.kind_of?(Array)
            m = "#{key} must be an Array."
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end

      def define_methods_for_hash_only_keys
        define_accessor_methods(*hash_only_keys) do |key, val|
          unless val.kind_of?(Hash)
            m = "#{key} must be a Hash."
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end

      def define_methods_for_abstract_resource_only_keys
        # values in this case: an array of hashes with { key: 'k', type: Class }
        abstract_resource_only_keys.each do |hsh|
          key = hsh[:key]
          type = hsh[:type]

          define_accessor_methods(key) do |k, val|
            unless val.kind_of?(type)
              m = "#{k} must be an #{type}."
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end
      end

      def define_methods_for_string_only_keys
        define_accessor_methods(*string_only_keys) do |key, val|
          unless val.kind_of?(String)
            m = "#{key} must be a String."
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end

      def define_methods_for_int_only_keys
        define_accessor_methods(*int_only_keys) do |key, val|
          unless val.kind_of?(Integer) && val > 0
            m = "#{key} must be a positive Integer."
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end

      def define_methods_for_numeric_only_keys
        define_accessor_methods(*numeric_only_keys) do |key, val|
          unless val.kind_of?(Numeric) && val > 0
            m = "#{key} must be a positive Integer or Float."
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end

      def define_methods_for_uri_only_keys
        define_accessor_methods(*uri_only_keys) do |key, val|
          unless val.kind_of?(String) && val =~ URI::regexp
            m = "#{key} must be a String containing a URI."
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end

      def define_accessor_methods(*keys, &validation)
        keys.each do |key|
          # Setter
          define_singleton_method("#{key}=") do |val|
            validation.call(key, val) if block_given?
            self.send('[]=', key, val)
          end
          if key.camelize(:lower) != key
            define_singleton_method("#{key.camelize(:lower)}=") do |val|
              validation.call(key, val) if block_given?
              self.send('[]=', key, val)
            end
          end
          # Getter
          define_singleton_method(key) do
            self[key] ||= []
            self[key]
          end
          if key.camelize(:lower) != key
            define_singleton_method(key.camelize(:lower)) do
              self.send('[]', key)
            end
          end
        end
      end

    end
  end
end
