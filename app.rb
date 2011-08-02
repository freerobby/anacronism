require "rubygems"
require "pony"
require "sinatra"

use Rack::Auth::Basic, "Access Restricted" do |username, password|
  username == ENV['HTTP_USER'] && password == ENV['HTTP_PASSWORD']
end

get '/' do
  consecutive_emails = ENV["CONSECUTIVE_EMAILS"].to_i
  last_ping = nil
  last_ping = Time.at(ENV["LAST_PING_RECEIVED_AT"].to_i).to_i if !ENV["LAST_PING_RECEIVED_AT"].nil? && ENV["LAST_PING_RECEIVED_AT"].length > 0
  this_ping = Time.now.to_i
  if !last_ping.nil? && (this_ping - last_ping > ENV["MAX_INTERVAL"].to_i) && consecutive_emails.to_i < 3
    consecutive_emails += 1
    Pony.mail :to => ENV["NOTIFY_LIST"],
              :from => ENV["EMAIL_FROM"],
              :subject => "[Anacronism] Cron Interval Exceeded #{ENV["MAX_INTERVAL"]} Seconds",
              :body => "The last cron interval was #{this_ping - last_ping} seconds.#{' This is the third and final notice.' if consecutive_emails == 3}"
  elsif last_ping.nil? || (this_ping - last_ping <= ENV["MAX_INTERVAL"].to_i)
    consecutive_emails = 0
  end
  
  ENV["LAST_PING_RECEIVED_AT"] = this_ping.to_s
  ENV["CONSECUTIVE_EMAILS"] = consecutive_emails.to_s
  "ACK"
end
