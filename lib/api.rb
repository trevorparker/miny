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
      @user ||= User.new(ip: @env['REMOTE_ADDR'], key: params[:key])
    end

    def filter
      if user.filter(redis)
        error!({ error: true, errortext: 'Too many requests' }, 429)
      elsif !params[:key].nil? && !user.authorized?(redis)
        error!({ error: true, errortext: 'Invalid API key' }, 403)
      end
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
        url = URL.new(sid: params[:sid])
        response = url.expand(redis)
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
      url = URL.new(url: params[:url])
      response = url.shorten(redis, @env['REMOTE_ADDR'])
      return response unless response.nil?
      error!({ error: true, errortext: 'Internal server error' }, 500)
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
    return spec
  end

  resource :user do
    desc 'Request a time-sensitive registration token'
    get :token do
      response = user.token(redis)
      return response unless response.nil?
      error!({ error: true, errortext: 'Unable to generate token' }, 400)
    end

    desc 'Register a new user'
    params do
      requires :token, type: String, desc: 'A valid registration token'
    end
    post :register do
      filter
      response = user.register!(redis, params[:token])
      return response unless response.nil?
      error!({ error: true, errortext: 'Unable to register user' }, 400)
    end
  end
end
