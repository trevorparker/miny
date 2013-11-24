# This class handles user authentication and request throttling.
class User
  def initialize(args)
    @max_requests_hour = 100
    @max_requests_minute = 10
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end

  def filter(redis)
    return true if @ip.nil?
    hour_tokens, minute_tokens, _, _ = record_request(redis, @ip)

    if authorized?(redis)
      @max_requests_hour = 500
      @max_requests_minute = 50
    end

    hour_tokens > @max_requests_hour || minute_tokens > @max_requests_minute
  end

  def token(redis)
    token = SecureRandom.uuid
    redis.set("token:#{token}", 1)
    redis.expire("token:#{token}", 60)

    { error: false, token: token }
  end

  def register!(redis, token)
    return unless valid_token?(redis, token)
    redis.del("token:#{token}")

    @key ||= generate_key(redis)
    result = redis.set("apikey:#{@key}", 1)
    return if result.nil?

    { error: false, key: @key }
  end

  def authorized?(redis)
    @authorized ||= redis.exists("apikey:#{@key}")
  end

  private

  def record_request(redis, ip)
    time_now = Time.now.to_i
    epoch_hour = time_now / 3600
    epoch_minute = time_now / 60
    redis.pipelined do
      redis.zincrby("traffic:#{epoch_hour}", 1, ip)
      redis.zincrby("traffic:#{epoch_minute}", 1, ip)
      redis.expire("traffic:#{epoch_hour}", 3600)
      redis.expire("traffic:#{epoch_minute}", 60)
    end
  end

  def generate_key(redis, key = '')
    loop do
      key = SecureRandom.hex
      return key unless redis.exists("apikey:#{key}")
    end
  end

  def valid_token?(redis, token = '')
    redis.exists("token:#{token}")
  end
end
