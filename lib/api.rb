require 'grape'
require 'redis'
require './lib/url'
require './lib/user'

# Miny API endpoint
class API < Grape::API
  version 'v1', using: :path
  format :json

  helpers do
    def redis
      @redis ||= Redis.new(port: 6379, db: 1)
    end

    def user
      @user ||= User.new(
        ip: request.ip,
        user_agent: request.user_agent,
        referrer: request.referrer,
        key: params[:key],
        redis: redis
      )
    end

    def filter
      if user.throttled?
        error!({ error: true, errortext: 'Too many requests' }, 429)
      elsif !params[:key].nil? && !user.authorized?
        error!({ error: true, errortext: 'Invalid API key' }, 403)
      end
    end

    def generate_token(ttl = 60)
      token = SecureRandom.uuid
      redis.set("token:#{token}", 1)
      redis.expire("token:#{token}", ttl)
      token
    end
  end

  resource :url do

    desc 'Expand a shortened URL'
    params do
      requires :sid, type: String, desc: 'A shortened URL ID to expand'
    end
    route_param :sid do
      get do
        filter
        url = URL.new(sid: params[:sid], redis: redis)
        response = url.expand
        return response unless response.nil?
        error!({ error: true, errortext: 'Gone' }, 410)
      end
    end

    desc 'Shorten a URL'
    params do
      requires :url, type: String, desc: 'A valid URL to shorten'
    end
    post do
      filter
      url = URL.new(url: params[:url], redis: redis)
      response = url.shorten(@env['REMOTE_ADDR'])
      return response unless response.nil?
      error!({ error: true, errortext: 'Unable to shorten URL' }, 400)
    end

  end

  resource :user do

    desc 'Request a time-sensitive registration token'
    get :token do
      token = generate_token
      if token.nil?
        error!({ error: true, errortext: 'Unable to generate token' }, 400)
      else
        { error: false, token: token }
      end
    end

    desc 'Register a new user'
    params do
      requires :token, type: String, desc: 'A valid registration token'
    end
    post :register do
      filter
      response = user.register!(params[:token])
      return response unless response.nil?
      error!({ error: true, errortext: 'Unable to register user' }, 400)
    end

  end

  desc 'Describe the API specification'
  get :spec do
    spec = {}
    API.routes.each do |route|
      path = route.route_path
      version = route.route_version
      spec[path.gsub('(.:format)', '').gsub(':version', version)] = {
        description: route.route_description || 'No description available',
        method: route.route_method,
        params: route.route_params
      }
    end
    spec
  end
end
