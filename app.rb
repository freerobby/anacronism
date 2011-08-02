require "sinatra"

require 'rubygems'
require 'sinatra'

use Rack::Auth::Basic, "Access Restricted" do |username, password|
  username == ENV['HTTP_USER'] && password == ENV['HTTP_PASSWORD']
end

get '/' do
  "ACK"
end
