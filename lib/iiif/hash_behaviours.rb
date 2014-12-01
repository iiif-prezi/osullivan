require 'forwardable'

module IIIF
  module HashBehaviours
    extend Forwardable

    # TODO:
    #  * reject
    #  * replace

    def_delegators :@data, :[], :[]=, :camelize_keys, :delete, :empty?,
    :fetch, :has_key?, :has_value?, :include?, :insert, :insert_after,
    :insert_before, :key, :key?, :keys, :length, :member?, :shift, :size,
    :snakeize_keys, :store, :unshift, :value?, :values


    ###
    # Methods that take a block and should return an instance (self or a new'
    # instance) have been overridden to do so, rather than an'
    # ActiveSupport::OrderedHash based on the internal hash

    SIMPLE_SELF_RETURNERS = %w[delete_if each each_key each_value keep_if]

    SIMPLE_SELF_RETURNERS.each do |method_name|
      define_method(method_name) do |*arg, &block|
        unless block.nil? # block_given? doesn't seem to work in this context
          @data.send(method_name, *arg, &block)
          return self
        else
          @data.send(method_name)
        end
      end
    end

    # Clear is the only method that returns self but doesn't accept a block
    def clear
      @data.clear
      return self
    end

    # Returns a new instance of this class containing the contents of'
    # another_obj. The argument can be any object that implements two
    # methods:
    #
    #    obj.each { |k,v| block }
    #    obj.has_key?
    #
    # If no block is specified, the value for entries with duplicate keys'
    # will be those of the argument, but at the index of the original; all'
    # other entries will be appended to the end.
    #
    # If a block is specified the value for each duplicate key is determined'
    # by calling the block with the key, its value in hsh and its value in'
    # another_obj.
    def merge another_obj
      new_instance =  self.class.new
      # self.clone # Would this be better? What happens to other attributes of the class?
      if block_given?
        self.each do |k,v|
          if another_obj.has_key? k
            new_instance[k] = yield(k, self[k], another_obj[k])
          else
            new_instance[k] = v
          end
        end
      else
        self.each { |k,v| new_instance[k] = v }
        another_obj.each { |k,v| new_instance[k] = v }
      end
      new_instance
    end

    # Adds the entries from another obj to this one. The argument can be any
    # object that implements two methods:
    #
    #    obj.each { |k,v| block }
    #    obj.has_key?
    #
    # If no block is specified, the value for entries with duplicate keys'
    # will be those of the argument, but at the index of the original; all'
    # other entries will be appended to the end.
    #
    # If a block is specified the value for each duplicate key is determined'
    # by calling the block with the key, its value in hsh and its value in'
    # another_obj.
    def merge! another_obj
      if block_given?
        self.each do |k,v|
          if another_obj.has_key? k
            self[k] = yield(k, self[k], another_obj[k])
          else
            self[k] = v
          end
        end
      else
        self.each { |k,v| self[k] = v }
        another_obj.each { |k,v| self[k] = v }
      end
      self
    end
    alias update merge!

    # Deletes entries for which the supplied block evaluates to true.
    # Equivalent to #delete_if, but returns nil if there were no changes
    def reject!
      if block_given?
        return_nil = true
        @data.each do |k, v|
          if yield(k, v)
            @data.delete(k)
            return_nil = false
          end
        end
        return return_nil ? nil : self
      else
        return self.data.reject!
      end
    end

    # Returns a new instance consisting of entries for which the block returns
    # true. Not that an enumerator is not available for the OrderedHash'
    # implementation
    def select
      new_instance = self.class.new
      if block_given?
        @data.each { |k,v| new_instance.data[k] = v if yield(k,v) }
      end
      return new_instance
    end

    # Deletes entries for which the supplied block evaluates to false.
    # Equivalent to Hash#keep_if, but returns nil if no changes were made.
    def select!
      if block_given?
        return_nil = true
        @data.each do |k,v|
          unless yield(k,v)
            @data.delete(k)
            return_nil = false
          end
        end
        return nil if return_nil
      end
      self
    end

  end

end

