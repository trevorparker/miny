require 'bundler'
require 'rubygems'
require './config'
require './lib/app'
require './lib/api'

Bundler.require

run Rack::Cascade.new [API, App]
