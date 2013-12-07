# This class exposes all URL <-> short URL ID conversion methods,
# as well as methods for gathering metadata about a particular short URL ID.
class URL
  attr_reader :sid, :url

  def initialize(args)
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end

  def shorten(ip)
    return if @url.nil?

    @url = "http://#{@url}" unless @url.match(%r(^https?\://))
    return if @url.match(%r(^https?\://$)) # There's a $ -- empty URL!

    @sid = @redis.hget("url:#{@url}", 'sid')

    if @sid.nil?
      @sid = generate_sid
      @stats = SecureRandom.uuid
      record_sid(@sid, @url, @stats, ip)
    end

    { error: false, sid: @sid, url: @url, stats: @stats }
  end

  def expand(redirecting = false, user = nil)
    return if @sid.nil?

    @url = expand_sid(@sid)
    return if @url.nil?

    record_visit(url, user) if redirecting == true && !user.nil?

    { error: false, sid: @sid, url: @url }
  end

  private

  def generate_sid(sid = '')
    chars = [*'a'..'z', *'A'..'Z', *'0'..'9']

    loop do
      5.times { sid << chars[rand(chars.length)] }
      return sid unless @redis.sismember('sids', sid)
    end
  end

  def record_sid(sid, url, stats, ip)
    @redis.pipelined do
      @redis.hset("url:#{url}", 'sid', sid)
      @redis.hmset(
        "sid:#{sid}", 'url', url, 'stats', stats,
        'created_at', Time.now.to_i, 'created_by', ip
      )
      @redis.sadd('urls', url)
      @redis.sadd('sids', sid)
    end
  end

  def expand_sid(sid)
    @redis.hget("sid:#{sid}", 'url')
  end

  def record_visit(url, user, visit_id = SecureRandom.uuid)
    @redis.pipelined do
      @redis.hmset(
        "visitor:#{visit_id}", 'ip', user.ip,
        'user_agent', user.user_agent, 'referrer', user.referrer,
        'visited_at', Time.now.to_i
      )
      @redis.hincrby("url:#{url}", 'visits', 1)
      @redis.hincrby("visits:#{url}:#{user.ip}", 'count', 1)
      @redis.rpush("visits:#{url}", visit_id)
    end
  end
end
