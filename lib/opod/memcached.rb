# specifications:
# http://cvs.danga.com/browse.cgi/wcmtools/memcached/doc/protocol.txt?rev=HEAD&content-type=text/plain
#
# very simple (= very fast) client for memcached
#
# i found the Ruby-MemCache library a little bit buggy and complicated, so i made my own before
# fixing it ;)
#
# TODO socket disconnection handling
# TODO error handling
# TODO multiple servers connections

require "socket"

module Opod

  class MemCached

    setting :address, :default => "localhost", :doc => "Server address"
    setting :port, :default => 11211, :doc => "Server port"

    def initialize(name = "cache", keepalive = nil)
      @sock = TCPSocket.new(MemCached.address, MemCached.port)
      @name = name
      @keepalive = keepalive
    end

    def []=(k,v)
      if @keepalive
        exptime = (Time.now + @keepalive).to_i
      else
        exptime = 0
      end

      data = Marshal.dump(v)
      @sock.print("set #{@name}:#{k} 0 #{exptime} #{data.size}\r\n#{data}\r\n")
      response = @sock.gets # "STORED\r\n"
      v
    end
    alias_method :set, :[]=

    def [](k)
      @sock.print("get #{@name}:#{k}\r\n")
      resp = @sock.gets
      if resp == "END\r\n"
        return nil
      end

      #dummy, key, flags, size
      size = resp.split(/ /).last.to_i
      raw_data = @sock.read(size)
      @sock.gets # \r\n
      @sock.gets # END\r\n
      Marshal.load( raw_data )
    end
    alias_method :get, :[]

    def delete(k)
      @sock.print("delete #{@name}:#{k}\r\n")
      @sock.gets # "DELETED\r\n"
    end

    def gc!
      # garbage collection is handled by the memcache server
    end

  end

end
