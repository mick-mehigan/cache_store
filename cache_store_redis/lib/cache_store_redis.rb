require "cache_store_redis/version"
require 'redis'
require 'oj'

#This class is used to implement a redis cache store.
#This class is used for interacting with a redis based cache store.
class RedisCacheStore

  def initialize(namespace = nil)
    @namespace = namespace
    @client = Redis.new
  end

  #This method is called to configure the connection to the cache store.
  def configure(host = 'localhost', port = 6379, db = 'default', password = nil)
    config = { :host => host, :port => port, :db => db }
    if password != nil
      config[:password] = password
    end
    @client = Redis.new(config)
  end

  #This method is called to set a value within this cache store by it's key.
  #
  # @param key [String] This is the unique key to reference the value being set within this cache store.
  # @param value [Object] This is the value to set within this cache store.
  # @param expires_in [Integer] This is the number of seconds from the current time that this value should expire.
  def set(key, value, expires_in = 0)
    v = nil
    k = build_key(key)

    if value != nil
      v = Oj.dump(value)
    end

    @client.set(k, v)

    if expires_in > 0
      @client.expire(k, expires_in)
    end

  end

  #This method is called to get a value from this cache store by it's unique key.
  #
  # @param key [String] This is the unique key to reference the value to fetch from within this cache store.
  # @param expires_in [Integer] This is the number of seconds from the current time that this value should expire. (This is used in conjunction with the block to hydrate the cache key if it is empty.)
  # @param &block [Block] This block is provided to hydrate this cache store with the value for the request key when it is not found.
  # @return [Object] The value for the specified unique key within the cache store.
  def get(key, expires_in = 0, &block)

    k = build_key(key)

    value = @client.get(k)
    value = Oj.load(value) unless value == nil

    if value.nil? && block_given?
      value = yield
      set(k, value, expires_in)
    end

    return value
  end

  # This method is called to remove a value from this cache store by it's unique key.
  #
  # @param key [String] This is the unique key to reference the value to remove from this cache store.
  def remove(key)

    @client.del(build_key(key))

  end

  # This method is called to check if a value exists within this cache store for a specific key.
  #
  # @param key [String] This is the unique key to reference the value to check for within this cache store.
  # @return [Boolean] True or False to specify if the key exists in the cache store.
  def exist?(key)

    @client.exists(build_key(key))

  end

  private

  def build_key(key)
    k = ''
    if @namespace != nil
      k = @namespace + ':' + key.to_s
    elsif
      k = key.to_s
    end
    k
  end

end