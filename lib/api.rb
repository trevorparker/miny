require 'grape'

# Miny API endpoint
class API < Grape::API
  version 'v1', using: :path
  format :json

  resource :url do

    desc 'Expand a shortened URL'
    params do
      requires :sid, type: String, desc: 'A shortened URL ID to expand'
    end
    route_param :sid do
      get do
        error!({ error: true, errortext: 'Not implemented' }, 501)
      end
    end

    desc 'Shorten a URL'
    params do
      requires :url, type: String, desc: 'A valid URL to shorten'
    end
    post do
      error!({ error: true, errortext: 'Not implemented' }, 501)
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
end
