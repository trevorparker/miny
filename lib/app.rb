require 'sinatra'

# Miny main app
class App < Sinatra::Base
  get '/' do
    'I know nothing, yet!'
  end
end
