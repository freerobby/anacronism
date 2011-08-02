require "dalli"
require "pony"

task :cron do
  dc = Dalli::Client.new
  
  @last_ping_received_at = dc.get(:last_ping_received_at) || Time.now.to_i
  if (Time.now.to_i - @last_ping_received_at > ENV["MAX_INTERVAL"].to_i)
    Pony.mail :to => ENV["NOTIFY_LIST"],
              :from => ENV["EMAIL_FROM"],
              :subject => "[Anacronism] Cron Is Overdue",
              :body => "We have not received a ping from cron in #{Time.now.to_i - @last_ping_received_at} seconds."
  end
end