# This class exposes all URL <-> short URL ID conversion methods,
# as well as methods for gathering metadata about a particular short URL ID.
class URL
  attr_reader :sid, :url

  def initialize(args)
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end

  def shorten(redis, ip)
    return if @url.nil?

    @url = "http://#{@url}" unless @url.match(%r(^https?\://))
    @stats = nil
    @sid = redis.hget("url:#{@url}", 'sid')

    if @sid.nil?
      @sid = generate_sid(redis)
      @stats = SecureRandom.uuid
      record_sid(redis, @sid, @url, @stats, ip)
    end

    { error: false, sid: @sid, url: @url, stats: @stats }
  end

  def expand
  end

  private

  def generate_sid(redis, sid = '')
    chars = [*'a'..'z', *'A'..'Z', *'0'..'9']

    loop do
      5.times { sid << chars[rand(chars.length)] }
      return sid unless redis.sismember('sids', sid)
    end
  end

  def record_sid(redis, sid, url, stats, ip)
    redis.pipelined do
      redis.hset("url:#{url}", 'sid', sid)
      redis.hmset(
        "sid:#{sid}", 'url', url, 'stats', stats,
        'created_at', Time.now.to_i, 'created_by', ip
      )
      redis.sadd('urls', url)
      redis.sadd('sids', sid)
    end
  end
end