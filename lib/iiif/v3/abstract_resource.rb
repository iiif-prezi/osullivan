require_relative '../hash_behaviours'

module IIIF
  module V3
    class AbstractResource
      include IIIF::HashBehaviours

      # properties used by content resources only
      CONTENT_RESOURCE_PROPERTIES = %w[format height width duration]

      # used by Collection, AnnotationCollection
      PAGING_PROPERTIES = %w[first last next prev total start_index]

      # subclasses should override required_keys as appropriate, e.g. super + %w{ id }
      def required_keys
        %w[type]
      end

      # subclasses should override prohibited_keys as appropriate, e.g. super + PAGING_PROPERTIES
      def prohibited_keys
        %w[]
      end

      # NOTE: keys associated with a single resource type are not included below in xxx_keys methods:
      #  those single resource types should include additional keys by overriding xxx_keys as appropriate

      def any_type_keys
        # values *may* be multivalued
        # NOTE: for id: "Resources that do not require URIs [for ids] may be assigned blank node identifiers"
        %w[id logo viewing_hint related see_also within]
      end

      def string_only_keys
        %w[nav_date type format viewing_direction start_canvas]
      end

      def array_only_keys
        %w[metadata rights thumbnail rendering first last next prev items service]
      end

      def hash_only_keys
        %w[label requiredStatement summary]
      end

      def int_only_keys
        %w[height width total start_index]
      end

      def numeric_only_keys
        %w[duration]
      end

      def uri_only_keys
        %w[]
      end

      # Not every subclass is allowed to have viewingDirect, but when it is,
      # it must be one of these values
      def legal_viewing_direction_values
        %w[left-to-right right-to-left top-to-bottom bottom-to-top]
      end

      def legal_viewing_hint_values
        []
      end

      # Initialize a Presentation node
      # @param [Hash] hsh - Anything in this hash will be added to the Object.
      #   Order is only guaranteed if an ActiveSupport::OrderedHash is passed.
      # @param [boolean] include_context (default: false). Pass true if the
      #   context should be included.
      def initialize(hsh = {})
        if self.class == IIIF::V3::AbstractResource
          raise "#{self.class} is an abstract class. Please use one of its subclasses."
        end

        @data = IIIF::OrderedHash[hsh]
        define_methods_for_any_type_keys
        define_methods_for_string_only_keys
        define_methods_for_array_only_keys
        define_methods_for_hash_only_keys
        define_methods_for_int_only_keys
        define_methods_for_numeric_only_keys
        define_methods_for_uri_only_keys
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
          IIIF::V3::Presentation::Service.from_ordered_hash(ordered_hash)
        end
      end

      def validate
        required_keys.each do |k|
          unless has_key?(k)
            m = "A(n) #{k} is required for each #{self.class}"
            raise IIIF::V3::Presentation::MissingRequiredKeyError, m
          end
        end

        prohibited_keys.each do |k|
          if has_key?(k)
            m = "#{k} is a prohibited key in #{self.class}"
            raise IIIF::V3::Presentation::ProhibitedKeyError, m
          end
        end

        uri_only_keys.each do |k|
          if self[k]
            vals = *self[k]
            vals.each { |val| validate_uri(val, k) }
          end
        end

        # NOTE: self.define_methods_for_xxx_only_keys provides some validation at assignment time
        #  currently, there is NO validation when key values are assigned directly with hash syntax,
        #  e.g. my_image_resource['format'] = 'image/jpeg'

        # Viewing Direction values
        if has_key?('viewing_direction') && !legal_viewing_direction_values.include?(self['viewing_direction'])
          m = "viewingDirection must be one of #{legal_viewing_direction_values}"
          raise IIIF::V3::Presentation::IllegalValueError, m
        end
        # Viewing Hint can be an Array ("Any resource type may have one or more viewing hints")
        if has_key?('viewing_hint')
          viewing_hint_val = self['viewing_hint']
          [*viewing_hint_val].each do |vh_val|
            unless legal_viewing_hint_values.include?(vh_val) || (vh_val.is_a?(String) && vh_val =~ URI::DEFAULT_PARSER.make_regexp)
              m = "viewingHint for #{self.class} must be one or more of #{legal_viewing_hint_values} or a URI"
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end
        # Metadata is Array; each entry is a Hash containing (only) 'label' and 'value' properties
        if has_key?('metadata') && self['metadata']
          unless self['metadata'].all? { |entry| entry.is_a?(Hash) }
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
        # Thumbnail is Array; each entry is a Hash or ImageResource containing (at least) 'id' and 'type' keys
        if has_key?('thumbnail') && self['thumbnail']
          unless self['thumbnail'].all? { |entry| entry.is_a?(IIIF::V3::Presentation::ImageResource) || entry.is_a?(Hash) }
            m = 'thumbnail must be an Array with Hash or ImageResource members'
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
          self['thumbnail'].each do |entry|
            thumb_keys = entry.keys
            unless thumb_keys.include?('id') && thumb_keys.include?('type')
              m = 'thumbnail members must include keys "id" and "type"'
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end
        # NavDate (navigation date)
        if has_key?('nav_date')
          begin
            Date.strptime(self['nav_date'], '%Y-%m-%dT%H:%M:%SZ')
          rescue ArgumentError
            m = "nav_date must be of form YYYY-MM-DDThh:mm:ssZ"
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
        # rights is Array; each entry is a Hash containing 'id' with a URI value
        if has_key?('rights')
          unless self['rights'].all? { |entry| entry.is_a?(Hash) }
            m = 'rights must be an Array with Hash members'
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
          self['rights'].each do |entry|
            unless entry.keys.include?('id')
              m = 'rights members must be a Hash including "id"'
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
            validate_uri(entry['id'], 'id') # raises IllegalValueError
          end
        end
        # rendering is Array; each entry is a Hash containing 'label' and 'format' keys
        if has_key?('rendering') && self['rendering']
          unless self['rendering'].all? { |entry| entry.is_a?(Hash) }
            m = 'rendering must be an Array with Hash members'
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
          self['rendering'].each do |entry|
            rendering_keys = entry.keys
            unless rendering_keys.include?('label') && rendering_keys.include?('format')
              m = 'rendering members must be a Hash including keys "label" and "format"'
              raise IIIF::V3::Presentation::IllegalValueError, m
            end
          end
        end
        # startCanvas is a String with a URI value
        return unless has_key?('start_canvas') && self['start_canvas'].is_a?(String)

        validate_uri(self['start_canvas'], 'startCanvas') # raises IllegalValueError
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
      #  * include_context: (true|false). Adds the @context to the top of the
      #      document if it doesn't exist. Default: true.
      #  * sort_json_ld_keys: (true|false). Brings all properties starting with
      #      '@'. Default: true. to the top of the document and sorts them.
      def to_ordered_hash(opts = {})
        include_context = opts.fetch(:include_context, true)
        self['@context'] = IIIF::V3::Presentation::CONTEXT if include_context && !has_key?('@context')
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
        type = IIIF::V3::AbstractResource.get_descendant_class_by_jld_type(hsh['type']) if hsh.has_key?('type')
        new_object = type.nil? ? default_klass.new : type.new

        hsh.keys.each do |key|
          new_key = key.underscore == key ? key : key.underscore
          if new_key == 'service'
            new_object[new_key] = hsh[key].map do |entry|
              IIIF::V3::AbstractResource.from_ordered_hash(entry, IIIF::V3::Presentation::Service)
            end
          elsif new_key == 'body'
            new_object[new_key] = IIIF::V3::AbstractResource.from_ordered_hash(hsh[key], IIIF::V3::Presentation::Resource)
          elsif hsh[key].is_a?(Hash)
            new_object[new_key] = IIIF::V3::AbstractResource.from_ordered_hash(hsh[key])
          elsif hsh[key].is_a?(Array)
            new_object[new_key] = []
            hsh[key].each do |member|
              new_object[new_key] << if new_key == 'service'
                                       IIIF::V3::AbstractResource.from_ordered_hash(member, IIIF::V3::Presentation::Service)
                                     elsif member.is_a?(Hash)
                                       IIIF::V3::AbstractResource.from_ordered_hash(member)
                                     else
                                       member
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
        define_accessor_methods(*array_only_keys) do |key, val|
          unless val.is_a?(Array)
            m = "#{key} must be an Array."
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end

      def define_methods_for_hash_only_keys
        define_accessor_methods(*hash_only_keys) do |key, val|
          unless val.is_a?(Hash)
            m = "#{key} must be a Hash."
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end

      def define_methods_for_string_only_keys
        define_accessor_methods(*string_only_keys) do |key, val|
          unless val.is_a?(String)
            m = "#{key} must be a String."
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end

      def define_methods_for_int_only_keys
        define_accessor_methods(*int_only_keys) do |key, val|
          unless val.is_a?(Integer) && val > 0
            m = "#{key} must be a positive Integer."
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end

      def define_methods_for_numeric_only_keys
        define_accessor_methods(*numeric_only_keys) do |key, val|
          unless val.is_a?(Numeric) && val > 0
            m = "#{key} must be a positive Integer or Float."
            raise IIIF::V3::Presentation::IllegalValueError, m
          end
        end
      end

      def define_methods_for_uri_only_keys
        define_accessor_methods(*uri_only_keys) { |key, val| validate_uri(val, key) }
      end

      def define_accessor_methods(*keys, &validation)
        keys.each do |key|
          # Setter
          define_singleton_method("#{key}=") do |val|
            validation.call(key, val) if block_given?
            send('[]=', key, val)
          end
          if key.camelize(:lower) != key
            define_singleton_method("#{key.camelize(:lower)}=") do |val|
              validation.call(key, val) if block_given?
              send('[]=', key, val)
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

      private

      def validate_uri(val, key)
        return if val.is_a?(String) && val =~ /\A#{URI::DEFAULT_PARSER.make_regexp}\z/

        m = "#{key} value must be a String containing a URI for #{self.class}"
        raise IIIF::V3::Presentation::IllegalValueError, m
      end
    end
  end
end
