require "rubygems"
require "dalli"
require "pony"
require "sinatra"

set :cache, Dalli::Client.new

use Rack::Auth::Basic, "Access Restricted" do |username, password|
  username == ENV['HTTP_USER'] && password == ENV['HTTP_PASSWORD']
end

get '/' do
  @consecutive_emails = settings.cache.get(:consecutive_emails) || 0
  @last_ping_received_at = settings.cache.get(:last_ping_received_at) || Time.now.to_i
  
  this_ping_received_at = Time.now.to_i
  if (this_ping_received_at - @last_ping_received_at > ENV["MAX_INTERVAL"].to_i) && @consecutive_emails < 3
    @consecutive_emails += 1
    Pony.mail :to => ENV["NOTIFY_LIST"],
              :from => ENV["EMAIL_FROM"],
              :subject => "[Anacronism] Cron Interval Exceeded #{ENV["MAX_INTERVAL"]} Seconds",
              :body => "The last cron interval was #{this_ping_received_at - @last_ping_received_at} seconds.#{' This is the third and final notice.' if @consecutive_emails == 3}",
              :via => :smtp,
              :via_options => {
                :address => "smtp.sendgrid.net",
                :port => "25", 
                :domain => ENV["SENDGRID_DOMAIN"], 
                :authentication => :plain, 
                :user_name => ENV["SENDGRID_USERNAME"], 
                :password => ENV["SENDGRID_PASSWORD"]
              }
  elsif (this_ping_received_at - @last_ping_received_at <= ENV["MAX_INTERVAL"].to_i)
    @consecutive_emails = 0
  end
  
  settings.cache.set(:consecutive_emails, @consecutive_emails)
  settings.cache.set(:last_ping_received_at, this_ping_received_at)
  "ACK"
end

