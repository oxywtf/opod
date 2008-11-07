require "drb"
require "facets/settings"
require "nemo/memory"

module Opod

  # A cached backed in a DRb server.
  #
  # === Example
  #
  # This cache needs a corresponding DRb server. Here is how you
  # can setup the standard Nitro Drb server to keep a DrbCache:
  #
  # require 'glue/cache/memory'
  #
  # class MyDrbServer < Nitro::DrbServer
  #   def setup_drb_objects
  #     ..
  #     @my_cache = SyncHash.new
  #     DRb.start_service("druby://#{my_drb_address}:#{my_drb_port}", @my_cache)
  #     ..
  #   end
  # end
  #
  # MyDrbServer.start

  class DrbCache < MemoryCache

    # Initialize the cache.
    #
    # === Options
    #
    # :address = The address of the DRb cache object.
    # :port = The port of the DRb cache object.

    # The address of the Session cache / store (if distibuted).

    setting :address, :default => '127.0.0.1', :doc => 'The address of the Session cache'

    # The port of the Session DRb cache / store (if distributed).

    setting :port, :default => 9069, :doc => 'The port of the Session cache'


    def initialize(address = DrbCache.address, port = DrbCache.port)
      @hash = DRbObject.new(nil, "druby://#{address}:#{port}")
    end

  end

end
