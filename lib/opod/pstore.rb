require 'fileutils'
require 'pstore'
require 'tmpdir'

module Opod

  class PStoreCache

    setting :basedir, :default => File.join(Dir.tmpdir, 'nitro_file_cache'),
      :doc => 'Base directory for cache files'

    setting :max_tries, :default => 5, :doc => 'Maximum number of tries for cache operations'

    setting :tokens, :default => '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
      :doc => 'Tokens used when generating cache file names'

    def initialize(keepalive = nil)
      @keepalive = keepalive
      initialize_store
    end

    # Return the object stored under <i>key</i> from the cache.
    # If the object isn't present in the cache <b>nil</b> is returned.

    def [](key)
      current_try = 0
      begin
        current_try += 1
        @store.transaction(true) do
          @store.fetch(key, nil)[1]
        end
      rescue PStore::Error
        # Unable to return the requested object from the cache.
        # Create a new store and retry.
        initialize_store
        unless current_try > PStoreCache.max_tries
          retry
        else
          raise Exception.new("Unable to read from cache file #{@store.path}!")
        end
      end
    end

    # Store <i>obj</i> under <i>key</i> in the cache.

    def []=(key, obj)
      current_try = 0
      begin
        current_try += 1
        @store.transaction(false) do
          if @keepalive
            @store[key] = [Time.now + @keepalive, obj]
          else
            @store[key] = [nil, obj]
          end
        end
      rescue PStore::Error
        # Unable to store object.
        # Create a new store and retry.
        initialize_store
        unless current_try > PStoreCache.max_tries
          retry
        else
          raise Exception.new("Unable to write to cache file #{@store.path}!")
        end
      end
    end

    # Return all objects stored in the cache.

    def all
      current_try = 0
      begin
        current_try += 1
        @store.transaction(true) do
          @store.roots.inject([]) do |result, current|
            result << @store[current][1]
          end
        end
      rescue PStore::Error
        # Unable to return stored objects from cache.
        # Create a new store and retry.
        initialize_store
        unless current_try > PStoreCache.max_tries
          retry
        else
          raise Exception.new("Unable to read from cache file #{@store.path}!")
        end
      end
    end

    # Delete the object stored under <i>key</i> in the cache.

    def delete(key)
      begin
        @store.transaction(false) do
          @store.delete(key)
        end
      rescue PStore::Error
        # Unable to delete object from the cache.
        # Create a new store.
        initialize_store
      end
    end

    # Remove all expired objects from the cache.

    def gc!
      return unless @keepalive
      begin
        now = Time.now
        @store.transaction(false) do
          @store.roots.each do |r|
            @store.delete(r) if now > @store[r][0]
          end
        end
      rescue PStore::Error
        # Unable to delete object from the cache.
        # Create a new store.
        initialize_store
      end
    end

    alias get []

    alias put []=

    alias read []

    alias values all

    alias write []=

    private

    # Generate a random filename using <i>tokens</i> and <i>length</i> as constraints.

    def generate_random_filename(tokens = PStoreCache.tokens, length = 16)
      filename = ''
      1.upto(length) do
        filename << tokens[rand(tokens.length)]
      end
      filename
    end

    # Initialize store with a random filename.
    # If no suitable filename can be found, raise an exception.

    def initialize_store
      # Create cache directory (if needed)
      unless File.exists?(PStoreCache.basedir) && File.directory?(PStoreCache.basedir)
        begin
          FileUtils.mkdir_p(PStoreCache.basedir)
        rescue Exception
          raise Exception.new("Unable to create cache directory #{PStoreCache.basedir}!")
        end
      end

      # Check whether the current_process has sufficient privilieges for reading/writing files to the cache directory

      unless File.readable?(PStoreCache.basedir) && File.writable?(PStoreCache.basedir)
        raise Exception.new("Insuffient priviligies for cache directory #{PStoreCache.basedir}!")
      end

      # generate a new random filename for the cache file

      current_try = 0

      begin
        current_try += 1
        filename = generate_random_filename
      end while File.exists?(File.join(PStoreCache.basedir, filename)) && current_try < PStoreCache.max_tries

      if current_try <= PStoreCache.max_tries
        begin
          @store = PStore.new(File.join(PStoreCache.basedir, filename))
        rescue Exception
          raise Exception.new('Unable to create cache file!')
        end
      else
        raise Exception.new('Unable to create cache file!')
      end
    end

  end

end
