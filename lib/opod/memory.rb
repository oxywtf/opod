require 'facets/synchash'

module Opod

  # A cache backed in memory.
  #--
  # This implementation is also the base for the Drb Cache.
  #++

  class MemoryCache
    attr :hash

    def initialize(options = {})
      if options[:sync]
        @hash = SyncHash
      else
        @hash = {}
      end
    end

    # Was orig. in Cache.

    def update(hash)
      hash.each { |key, value| self[key] = value }
    end

    # Get an object from the cache.

    def get(key, options = nil)
      @hash[key]
    end
    alias_method :read, :get
    alias_method :[], :get

    # Put an object in the cache.

    def set(key, value = nil, options = nil)
      @hash[key] = value
    end
    alias_method :put, :set
    alias_method :write, :set
    alias_method :[]=, :set

    # Delete an object from the cache.

    def delete(key, options = nil)
      @hash.delete(key)
    end
    alias_method :remove, :delete

    def delete_if(&block)
      @hash.delete_if(&block)
    end

    # Perform session garbage collection. Typically this method
    # is called from a cron like mechanism.

    def gc!
      delete_if { |key, s| s.expired? }
    end

    # Return the mapping.

    def mapping
      @hash
    end

    # Return all keys in the cache.

    def keys
      @hash.keys
    end

    # Return all objects in the cache.

    def all
      @hash.values
    end
    alias_method :values, :all

  end

end
