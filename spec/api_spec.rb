# Load the Sinatra app
require File.dirname(__FILE__) + '/../lib/api.rb'

require 'rspec'
require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

def app
  API
end

describe API do
  describe 'GET /v1/spec' do
    it 'responds with entries for spec, shorten, and expand' do
      get '/v1/spec'
      last_response.status.should == 200
      JSON.parse(last_response.body)['/v1/spec']['method'].should == 'GET'
      JSON.parse(last_response.body)['/v1/url']['method'].should == 'POST'
      JSON.parse(last_response.body)['/v1/url/:sid']['method'].should == 'GET'
    end
  end

  sid = ''
  describe 'POST /v1/url' do
    it 'responds with 201 created' do
      post '/v1/url', url: 'http://example.com'
      last_response.status.should == 201
      JSON.parse(last_response.body)['error'].should == false
      JSON.parse(last_response.body)['url'].should == 'http://example.com'
      sid = JSON.parse(last_response.body)['sid']
    end
  end

  describe 'GET /v1/url/:sid' do
    it 'responds with 200 found' do
      get "/v1/url/#{sid}"
      last_response.status.should == 200
      JSON.parse(last_response.body)['error'].should == false
      JSON.parse(last_response.body)['url'].should == 'http://example.com'
    end
  end

  describe 'GET NONEXISTENT /v1/url/:sid' do
    it 'responds with 410 gone' do
      get '/v1/url/noop'
      last_response.status.should == 410
      JSON.parse(last_response.body)['error'].should == true
    end
  end

  describe 'THRASH /v1/url' do
    it 'throttles after 10 attempts (4 already tried)' do
      6.times do
        post '/v1/url', url: 'http://example.com'
        last_response.status.should == 201
        JSON.parse(last_response.body)['error'].should == false
        JSON.parse(last_response.body)['url'].should == 'http://example.com'
      end

      post '/v1/url', url: 'http://example.com'
      last_response.status.should == 429
      JSON.parse(last_response.body)['error'].should == true
    end
  end
end
