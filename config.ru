require './lib/app.rb'
require './lib/api.rb'

run Rack::Cascade.new [API, App]
