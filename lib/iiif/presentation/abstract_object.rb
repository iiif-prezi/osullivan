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

      JSON_LD_PROPS ||= %w{type id context}
      # These types could be anything...right?
      ALLOWED_ANYWHERE_PROPS ||= %w{label description
        thumbnail attribution license logo see_also service related within}

      CONTEXT ||= 'http://iiif.io/api/presentation/2/context.json'
      INITIALIZABLE_KEYS ||= %w{@id @type}
      # Initialize a Presentation node
      # @param [Hash] hsh - Anything in this hash will be added to the Object.'
      #   Order is only guaranteed if an ActiveSupport::OrderedHash is passed.
      # @param [boolean] include_context (default: false). Pass true if the'
      #   context should be included.
      def initialize(hsh={}, include_context=false)
        @data = ActiveSupport::OrderedHash[hsh]
        unless hsh.has_key?('@context') || !include_context
          self['@context'] = CONTEXT
        end
        if self.class == IIIF::Presentation::AbstractObject
          raise "#{self.class} is an abstract class. Please use one of its subclasses."
        end
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

      # JSON-LD accessor/mutators, can't have '@' :-(.'
      # Consider '_prop' or something else?

      JSON_LD_PROPS.each do |jld_prop|
        # Setters
        define_method("#{jld_prop}=") do |arg|
          self.send('[]=', "@#{jld_prop}", arg)
        end
        # Getters
        define_method("#{jld_prop}") do
          self.send('[]', "@#{jld_prop}")
        end
      end

      # Array only
      def metadata=(arr)
        self['metadata'] = arr

      end
      def metadata
        self['metadata'] ||= []
        self['metadata']
      end

      def viewing_hint=(t)
        self['viewingHint'] = t
      end
      alias setViewingHint viewing_hint=

      ALLOWED_ANYWHERE_PROPS.each do |anywhere_prop|
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

      def to_hash
        self.tidy_empties
        self.validate
        @data
      end
      alias to_h to_hash

      def to_json
        self.tidy_empties
        self.validate
        @data.to_json
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
        #TODO
      end

      def data=(hsh)
        @data = hsh
      end

    end
  end
end

