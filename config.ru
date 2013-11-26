require './app'
require './lib/api'

run Rack::Cascade.new [API, App]
