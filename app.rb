require_relative 'config'
require 'sinatra'
require './lib/url'
require './lib/user'

# Miny main app
class App < Sinatra::Base
  get '/' do
    erb :'index/index'
  end

  get '/:sid' do
    redis = Redis.new(port: 6379, db: 1)
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
