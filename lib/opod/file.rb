require "uri"
require "fileutils"
require "tmpdir"

module Opod

  class FileCache

    setting :basedir, :default => "#{Dir.tmpdir}/nitro_file_cache", :doc => "The directory to store files"

    def initialize(name = "cache", keepalive = nil)
      @path = File.join(FileCache.basedir, name)
      @keepalive = keepalive

      FileUtils.mkdir_p(@path, :mode => 0700)
    end

    def []=(k,v)
      fn = File.join(@path, escape_filename(k.to_s) )
      encode_file(fn, v)
    end
    alias_method :set, :[]=

    def [](k)
      fn = File.join(@path, escape_filename(k.to_s) )
      return nil unless File.exists?(fn)
      decode_file(fn)
    end
    alias_method :get, :[]

    def delete(k)
      f = File.join(@path, escape_filename(k.to_s))
      File.delete(f) if File.exists?(f)
    end

    def gc!
      return unless @keepalive

      now = Time.now
      all.each do |fn|
        expire_time = File.stat(fn).atime + @keepalive
        File.delete(fn) if now > expire_time
      end
    end

    def all
      Dir.glob( File.join(@path, '*' ) )
    end

    private

    def decode_file(fn)
      val = nil
      File.open(fn,"rb") do |f|
        f.flock(File::LOCK_EX)
        val = Marshal.load( f.read )
        f.flock(File::LOCK_UN)
      end
      return val
    end

    def encode_file(fn, value)
      File.open(fn, "wb") do |f|
        f.flock(File::LOCK_EX)
        f.chmod(0600)
        f.write(Marshal.dump(value))
        f.flock(File::LOCK_UN)
      end
    end

    # need this for fat filesystems
    def escape_filename(fn)
      URI.escape(fn, /["\/:;|=,\[\]]/)
    end

  end

end

