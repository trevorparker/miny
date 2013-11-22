# This class handles user authentication and request throttling.
class User
  def initialize(args)
    @max_requests_hour = 100
    @max_requests_minute = 10
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end

  def throttle(redis)
    return true if @ip.nil?
    hour_tokens, minute_tokens, _, _ = record_request(redis, @ip)
    hour_tokens >= @max_requests_hour || minute_tokens >= @max_requests_minute
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
end
