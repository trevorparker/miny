require 'rack/test'
require 'redis'

ENV['RACK_ENV'] = 'test'
require File.join(File.dirname(__FILE__), '..', 'config/environments/test')

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.after(:suite) do
    Redis.new(port: REDIS_PORT, db: REDIS_DB).flushdb
  end
end
