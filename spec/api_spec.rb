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

  describe 'GET /v1/url/:sid' do
    it 'responds with 501 not implemented' do
      get '/v1/url/short'
      last_response.status.should == 501
      JSON.parse(last_response.body)['errortext'].should == 'Not implemented'
    end
  end

  describe 'POST /v1/url' do
    it 'responds with 501 not implemented' do
      post '/v1/url', url: 'http://example.com'
      last_response.status.should == 501
      JSON.parse(last_response.body)['errortext'].should == 'Not implemented'
    end
  end
end
