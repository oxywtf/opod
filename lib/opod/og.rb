require 'og'
require 'base64'

module Opod

  class OgCached
    include Og::EntityMixin

    property :unique_id, String, :sql => 'PRIMARY KEY'
    property :expires, Time
    property :cache_name, String
    property :content, String

    set_primary_key :unique_id, String
  end

  class OgCache

    def initialize(cache_name, keepalive = nil)
      @cache_name = cache_name
      @keepalive = keepalive
    end

    def []=(k,v)
      unless s = OgCached.find_by_unique_id_and_cache_name(k.to_s, @cache_name)
        s = OgCached.new
        s.cache_name = @cache_name
        s.expires = Time.now + @keepalive if @keepalive
        s.unique_id = k.to_s
      end
      #s.content = v.to_yaml
      s.content = encode(v)
      s.insert
    end

    def [](k)
      s = OgCached.find_by_unique_id_and_cache_name(k.to_s, @cache_name)
      decode(s.content) if s
    end

    def gc!
      OgCached.find(:condition => ["expires < ? AND cache_name = ?", Time.now, @cache_name]).each {|s| s.delete }
    end

    def all
      OgCached.find_by_cache_name(@cache_name)
    end

    private

    def encode(c)
      Base64.encode64(Marshal.dump(c))
    end

    def decode(c)
      Marshal::load(Base64.decode64(c))
      #s.content = YAML::load(s.content)
    end

  end
end
