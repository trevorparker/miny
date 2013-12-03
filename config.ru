require './config'
require './lib/app'
require './lib/api'

run Rack::Cascade.new [API, App]
