require 'spec_helper'
require_relative '../../config'
require_relative '../../lib/app'
require_relative '../../lib/url'

describe App do
  def app
    App
  end

  describe 'GET /' do
    it 'responds with 200 OK' do
      get '/'
      last_response.status.should == 200
    end
  end

  describe 'GET /:sid' do
    it '301 redirects' do
      redis = Redis.new(port: REDIS_PORT, db: REDIS_DB)
      url = URL.new(url: 'http://example.com', redis: redis)
      sid = url.shorten(ENV['REMOTE_ADDR'])[:sid]

      get "/#{sid}"
      last_response.status.should == 301
      last_response.location.should == 'http://example.com'
    end
  end
end
