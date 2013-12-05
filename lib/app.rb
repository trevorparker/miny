require 'sinatra'
require_relative 'url'
require_relative 'user'

env = ENV['RACK_ENV'] || 'test'
require File.join(File.dirname(__FILE__), '..', "config/environments/#{env}")

# Miny main app
class App < Sinatra::Base
  configure do
    set :views, File.join(File.dirname(__FILE__), '..', 'views')
  end

  get '/' do
    erb :'index/index'
  end

  get '/:sid' do
    redis = Redis.new(port: REDIS_PORT, db: REDIS_DB)
    user = User.new(
        ip: request.ip,
        user_agent: request.user_agent,
        referrer: request.referrer,
        key: params[:key],
        redis: redis
    )

    url = URL.new(sid: params[:sid], redis: redis)
    destination = url.expand(true, user)[:url]
    halt 404, 'Not found' if destination.nil?
    redirect destination, 301
  end
end
