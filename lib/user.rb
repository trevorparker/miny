# This class handles user authentication and request throttling.
class User
  attr_reader :key, :max_requests, :ip, :user_agent, :referrer

  def initialize(args)
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end

    @max_requests = { hour: 100, minute: 10 }
  end

  def register!(token)
    return unless valid_token?(token)

    @redis.del("token:#{token}")
    @key ||= generate_key
    result = @redis.set("apikey:#{@key}", 1)
    return if result.nil?

    { error: false, key: @key }
  end

  def authorized?
    @authorized ||= @redis.exists("apikey:#{@key}")
  end

  def throttled?
    return true if @ip.nil?

    hour_reqs, minute_reqs, _, _ = record_request(@ip)
    @max_requests = { hour: 500, minute: 50 } if authorized?
    hour_reqs > @max_requests[:hour] || minute_reqs > @max_requests[:minute]
  end

  private

  def record_request(ip)
    now = Time.now.to_i
    epoch_hour = now / 3600
    epoch_minute = now / 60
    @redis.pipelined do
      @redis.zincrby("traffic:#{epoch_hour}", 1, ip)
      @redis.zincrby("traffic:#{epoch_minute}", 1, ip)
      @redis.expire("traffic:#{epoch_hour}", 3600)
      @redis.expire("traffic:#{epoch_minute}", 60)
    end
  end

  def generate_key(key = '')
    loop do
      key = SecureRandom.hex
      return key unless @redis.exists("apikey:#{key}")
    end
  end

  def valid_token?(token = '')
    @redis.exists("token:#{token}")
  end
end
