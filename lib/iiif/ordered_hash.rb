require 'active_support/inflector'

module IIIF
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
      tmp = IIIF::OrderedHash.new
      index = length + 1 + index if index < 0
      if index < 0
        m = "Index #{index} is too small for current length (#{length})"
        raise IndexError, m
      end
      if index > 0
        i = 0
        each do |k, v|
          tmp[k] = v
          delete(k)
          i += 1
          break if i == index
        end
      end
      tmp[key] = value
      tmp.merge!(self) # copy the remaining to tmp
      clear       # start over...
      merge!(tmp) # now put them all back
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
        insert_here(0, new_key, value, &block)
      else
        insert_here(0, new_key, value, existing_key)
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
        insert_here(1, new_key, value, &block)
      else
        insert_here(1, new_key, value, existing_key)
      end
    end

    # Delete any keys that are empty arrays
    def remove_empties
      keys.each do |key|
        delete(key) if (self[key].is_a?(Array) && self[key].empty?) || self[key].nil?
      end
    end

    # Covert snake_case keys to camelCase
    def camelize_keys
      keys.each_with_index do |key, i|
        if key != key.camelize(:lower)
          insert(i, key.camelize(:lower), self[key])
          delete(key)
        end
      end
      self
    end

    # Covert camelCase keys to snake_case
    def snakeize_keys
      keys.each_with_index do |key, i|
        if key != key.underscore
          insert(i, key.underscore, self[key])
          delete(key)
        end
      end
      self
    end

    # Prepends an entry to the front of the object.
    # Note that this is slightly different from Array#unshift in that new
    # entries must be added one at a time, i.e. unshift([k,v],[k,v],...) is
    # not currently supported.
    def unshift(k, v)
      insert(0, k, v)
      self
    end

    protected

    def insert_here(where, new_key, value, existing_key = nil)
      idx = nil
      if block_given?
        each_with_index do |(k, v), i|
          if yield(k, v)
            idx = i
            break
          end
        end
        raise KeyError, "Supplied block never evaluates to true" if idx.nil?
      else
        raise KeyError, "Existing key '#{existing_key}' does not exist" unless has_key?(existing_key)
        raise KeyError, "Supplied new key '#{new_key}' already exists" if has_key?(new_key)

        idx = keys.index(existing_key) + where
      end
      insert(idx, new_key, value)
      self
    end
  end
end
