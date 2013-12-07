require 'spec_helper'
require_relative '../../lib/api'

describe API do
  # rubocop:disable Void

  def app
    API
  end

  requests = 0
  describe 'GET /v1/spec' do
    it 'responds with entries for spec, shorten, and expand' do
      get '/v1/spec'
      last_response.status.should == 200
      JSON.parse(last_response.body)['/v1/spec']['method'].should == 'GET'
      JSON.parse(last_response.body)['/v1/url']['method'].should == 'POST'
      JSON.parse(last_response.body)['/v1/url/:sid']['method'].should == 'GET'
      # spec requests don't count against throttle
    end
  end

  token = ''
  describe 'GET TOKEN /v1/user/token' do
    it 'generates a registration token' do
      get '/v1/user/token'
      last_response.status.should == 200
      JSON.parse(last_response.body)['error'].should == false
      JSON.parse(last_response.body)['token'].length.should == 36
      token = JSON.parse(last_response.body)['token']
      # registration token requests don't count against throttle
    end
  end

  key = ''
  describe 'REGISTER USER /v1/user/register' do
    it 'registers a new user and provides an API key' do
      post '/v1/user/register', token: token
      last_response.status.should == 201
      JSON.parse(last_response.body)['error'].should == false
      JSON.parse(last_response.body)['key'].length.should == 32
      key = JSON.parse(last_response.body)['key']
      requests += 1
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
      requests += 1
    end
  end

  describe 'GET /v1/url/:sid' do
    it 'responds with 200 found' do
      get "/v1/url/#{sid}"
      last_response.status.should == 200
      JSON.parse(last_response.body)['error'].should == false
      JSON.parse(last_response.body)['url'].should == 'http://example.com'
      requests += 1
    end
  end

  describe 'GET NONEXISTENT /v1/url/:sid' do
    it 'responds with 410 gone' do
      get '/v1/url/noop'
      last_response.status.should == 410
      JSON.parse(last_response.body)['error'].should == true
      requests += 1
    end
  end

  describe 'THRASH /v1/url' do
    it 'allows exactly 10 attempts' do
      (10 - requests).times do
        post '/v1/url', url: 'http://example.com'
        last_response.status.should == 201
        JSON.parse(last_response.body)['error'].should == false
        JSON.parse(last_response.body)['url'].should == 'http://example.com'
        requests += 1
      end
    end

    it 'throttles after the 10th attempt' do
      post '/v1/url', url: 'http://example.com'
      last_response.status.should == 429
      JSON.parse(last_response.body)['error'].should == true
      requests += 1
    end
  end

  describe 'REGISTERED USER THRASH /v1/url' do
    it 'allows exactly 50 attempts' do
      (50 - requests).times do
        post '/v1/url', url: 'http://example.com', key: key
        last_response.status.should == 201
        JSON.parse(last_response.body)['error'].should == false
        JSON.parse(last_response.body)['url'].should == 'http://example.com'
        requests += 1
      end
    end

    it 'throttles after the 50th attempt' do
      post '/v1/url', url: 'http://example.com', key: key
      last_response.status.should == 429
      JSON.parse(last_response.body)['error'].should == true
      requests += 1
    end
  end
end
