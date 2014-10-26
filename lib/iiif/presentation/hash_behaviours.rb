module IIIF
  module Presentation
    module HashBehaviours
      # Appends to the end if k is not already in the Node, otherwise replaces
      # the value for the existing entry in the same place.
      def []= k,v
        if @data.select{ |entry| entry[0] == k } == []
          @data << [k,v]
        else
          idx = @data.find_index { |e| e[0] == k }
          @data[idx] = [k,v]
        end
      end

      # Returns the value associated with this k, or nil if the key is not 
      # present
      def [] k
        entry = @data.select { |entry| entry[0] == k }[0]
        if entry.nil?
          nil
        else
          entry[1]
        end
      end

      # Clear all entries
      # @return the empty instance
      def clear
        @data.clear 
        self
      end

      # Delete an entry.
      # @return the value associated with the key.
      def delete k
        @data.delete(@data.select { |entry| entry[0] == k }[0])[1]
      end

      def empty?
        @data.empty?
      end

      # Returns the value for the supplied key, or the supplied default
      # Raises an KeyError exception if no default is supplied and the key is 
      # not found.
      #
      # TODO:
      # if default is given, then that will be  <<-----
      # returned; if the optional code block is specified, then that will be 
      # run and its result returned.
      def fetch(k, default=nil)
        entry = @data.select { |entry| entry[0] == k }[0]
        if entry.nil? && default.nil?
          raise KeyError, "#{k} does not exist and no default supplied." 
        elsif entry.nil? && ! default.nil?
          default
        else
          entry[1]
        end
      end

      # @return true if there is an entry for the key.
      def has_key? k
        !@data.select { |entry| entry[0] == k }.empty?
      end
      alias member? has_key?
      alias include? has_key?
      alias key? has_key?

      # Returns true if there is an entry with the supplied value.
      def has_value? v
        !@data.select { |entry| entry[1] == v }.empty?
      end
      alias value? has_value?

      # Returns the key of an entry with the supplied value, or else nil.
      def key v
        entry = @data.select { |entry| entry[1] == v }[0]
        if entry.nil?
          nil
        else
          entry[0]
        end
      end
      
      # Returns a new array populated with the keys.
      def keys 
        @data.map { |e| e[0] }
      end

      # Removes one or more key-value pairs from the front of the object. If n=1 
      # (default) an Array [k,v] is returned. If n > 1 a Hash is returned.
      #
      # TODO: 
      #  * Should this return another instance of the class from which the
      #    entries were taken? Or some kind of Generic Node? Otherwise we 
      #    risk losing order. The Hash API doesn't support n...so that's an
      #    option too.
      #
      # @param [Integer] n. The number to shift. Default: 1
      def shift n=1
        if n == 1
          @data.shift(n)[0]
        else
          Hash[@data.shift(n)]
        end
      end

      # Prepends an entry to the front of the Node.
      def unshift k,v
        # TODO: support '...', i.e. http://www.ruby-doc.org/core-2.1.3/Array.html#method-i-unshift
        @data.unshift([k,v])
        self
      end
      
      # Returns a new array populated with the values from hsh. See also Hash#keys.
      def values
        @data.map { |e| e[1] }
      end


      # There are a bunch of methods that take blocks to consider...
      # each_value
      # each pair
    end
  end
end


