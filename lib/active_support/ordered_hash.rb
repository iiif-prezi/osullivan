require 'active_support/inflector'
require 'active_support/ordered_hash'

module ActiveSupport
  class OrderedHash < ::Hash

    # Insert a new key and value at the suppplied index.
    #
    # Note that this is slightly different from Array#insert in that new
    # entries must be added one at a time, i.e. insert(n, k, v, k, v...) is
    # not supported.
    #
    # @param [Integer] index
    # @param [Object] key
    # @param [Object] value
    def insert(index, key, value)
      tmp = ActiveSupport::OrderedHash.new
      index = self.length + 1 + index if index < 0
      if index < 0
        m = "Index #{index} is too small for current length (#{length})"
        raise IndexError, m
      end
      if index > 0
        i=0
        self.each do |k,v|
          tmp[k] = v
          self.delete(k)
          i+=1
          break if i == index
        end
      end
      tmp[key] = value
      tmp.merge!(self) # copy the remaining to tmp
      self.clear       # start over...
      self.merge!(tmp) # now put them all back
      self
    end

    # Insert a key and value before an existing key or the first entry for'
    # which the supplied block evaluates to true. The block takes precendence
    # over the supplied key.
    # Options:'
    #  * :existing_key (default: nil). If nil or not supplied then a block is required.
    #  * :new_key (required)
    #  * :value (required)
    # @raise KeyError if the supplied existing key is not found, the new
    # key exists, or the block never evaluates to true.
    def insert_before(hsh, &block)
      existing_key = hsh.fetch(:existing_key, nil)
      new_key = hsh[:new_key]
      value = hsh[:value]
      if block_given?
        self.insert_here(0, new_key, value, &block)
      else
        self.insert_here(0, new_key, value, existing_key)
      end
    end

    # Insert a key and value after an existing key or the first entry for'
    # which the supplied block evaluates to true. The block takes precendence
    # over the supplied key.
    # Options:'
    #  * :existing_key (default: nil). If nil or not supplied then a block is required.
    #  * :new_key (required)
    #  * :value (required)
    # @raise KeyError if the supplied existing key is not found, the new
    # key exists, or the block never evaluates to true.
    def insert_after(hsh, &block)
      existing_key = hsh.fetch(:existing_key, nil)
      new_key = hsh[:new_key]
      value = hsh[:value]
      if block_given?
        self.insert_here(1, new_key, value, &block)
      else
        self.insert_here(1, new_key, value, existing_key)
      end
    end

    # Delete any keys that are empty arrays
    def remove_empties
      self.keys.each do |key|
        if (self[key].kind_of?(Array) && self[key].empty?) || self[key].nil?
          self.delete(key)
        end
      end
    end

    # Covert snake_case keys to camelCase
    def camelize_keys
      self.keys.each_with_index do |key, i|
        if key != key.camelize(:lower)
          self.insert(i, key.camelize(:lower), self[key])
          self.delete(key)
        end
      end
      self
    end

    # Covert camelCase keys to snake_case
    def snakeize_keys
      self.keys.each_with_index do |key, i|
        if key != key.underscore
          self.insert(i, key.underscore, self[key])
          self.delete(key)
        end
      end
      self
    end


    # Prepends an entry to the front of the object.
    # Note that this is slightly different from Array#unshift in that new
    # entries must be added one at a time, i.e. unshift([k,v],[k,v],...) is
    # not currently supported.
    def unshift k,v
      self.insert(0, k, v)
      self
    end

    protected
    def insert_here(where, new_key, value, existing_key=nil, &block)
      idx = nil
      if block_given?
        self.each_with_index do |(k,v), i|
          if yield(k, v)
            idx = i
            break
          end
        end
        if idx.nil?
          raise KeyError, "Supplied block never evaluates to true"
        end
      else
        unless self.has_key?(existing_key)
          raise KeyError, "Existing key '#{existing_key}' does not exist"
        end
        if self.has_key?(new_key)
          raise KeyError, "Supplied new key '#{new_key}' already exists"
        end
        idx = self.keys.index(existing_key) + where
      end
      self.insert(idx, new_key, value)
      self
    end

  end
end
