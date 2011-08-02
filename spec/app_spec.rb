require File.dirname(__FILE__) + '/spec_helper'

require "timecop"

describe "Anacronism App" do
  include Rack::Test::Methods

  def app
    @app ||= Sinatra::Application
  end
  
  describe "no auth" do
    it "requires authentication" do
      get '/'
      last_response.status.should == 401
    end
  end
  
  describe "bad auth" do
    before do
      @old_user = ENV["HTTP_USER"]
      @old_pass = ENV["HTTP_PASSWORD"]
      ENV["HTTP_USER"] = "U"
      ENV["HTTP_PASSWORD"] = "p"
    end
    after do
      ENV["HTTP_USER"] = @old_user
      ENV["HTTP_PASSWORD"] = @old_pass
    end
    
    it "fails" do
      authorize ENV["HTTP_USER"], ENV["HTTP_PASSWORD"] + "fail"
      get '/'
      last_response.body.should_not == "ACK"
      last_response.status.should == 401
    end
  end
  
  describe "good auth" do
    before do
      @old_user = ENV["HTTP_USER"]
      @old_pass = ENV["HTTP_PASSWORD"]
      ENV["HTTP_USER"] = "U"
      ENV["HTTP_PASSWORD"] = "p" 
      authorize ENV["HTTP_USER"], ENV["HTTP_PASSWORD"]
    end
    after do
      ENV["HTTP_USER"] = @old_user
      ENV["HTTP_PASSWORD"] = @old_pass
    end
    it "succeeds" do
      get '/'
      last_response.body.should == "ACK"
      last_response.status.should == 200
    end
    it "stores time" do
      Timecop.freeze(Time.at(1312299572))
      get '/'
      ENV["LAST_PING_RECEIVED_AT"].should == "1312299572"
      Timecop.return
    end
    it "sends email if interval exceeds MAX_INTERVAL" do
      old_lpra = ENV["LAST_PING_RECEIVED_AT"]
      old_max_interval = ENV["MAX_INTERVAL"]
      
      ENV["LAST_PING_RECEIVED_AT"] = "1312299572"
      ENV["MAX_INTERVAL"] = "30"
      Timecop.freeze(Time.at(1312299603)) # 31 seconds later
      Pony.should_receive(:mail)
      get '/'
      Timecop.return
      
      ENV["MAX_INTERVAL"] = old_max_interval
      ENV["LAST_PING_RECEIVED_AT"] = old_lpra
    end
    it "does not send email if interval within MAX_INTERVAL" do
      old_lpra = ENV["LAST_PING_RECEIVED_AT"]
      old_max_interval = ENV["MAX_INTERVAL"]
      
      ENV["LAST_PING_RECEIVED_AT"] = "1312299572"
      ENV["MAX_INTERVAL"] = "30"
      Timecop.freeze(Time.at(1312299601)) # 29 seconds later
      Pony.should_not_receive(:mail)
      get '/'
      Timecop.return
      
      ENV["MAX_INTERVAL"] = old_max_interval
      ENV["LAST_PING_RECEIVED_AT"] = old_lpra
    end
    it "does not send email on first ping" do
      old_lpra = ENV["LAST_PING_RECEIVED_AT"]
      old_max_interval = ENV["MAX_INTERVAL"]
      
      ENV["LAST_PING_RECEIVED_AT"] = ""
      ENV["MAX_INTERVAL"] = "30"
      Pony.should_not_receive(:mail)
      get '/'
      
      ENV["MAX_INTERVAL"] = old_max_interval
      ENV["LAST_PING_RECEIVED_AT"] = old_lpra
    end
    
    it "sends max of 3 consecutive emails" do
      old_lpra = ENV["LAST_PING_RECEIVED_AT"]
      old_max_interval = ENV["MAX_INTERVAL"]
      old_consecutive_emails = ENV["CONSECUTIVE_EMAILS"]
      
      ENV["CONSECUTIVE_EMAILS"] = ""
      ENV["LAST_PING_RECEIVED_AT"] = "1312299572"
      ENV["MAX_INTERVAL"] = "30"
      
      Timecop.freeze(Time.at(1312299603)) # 31 seconds later
      Pony.should_receive(:mail)
      get '/'
      Timecop.return
      
      Timecop.freeze(Time.at(1312299634)) # 62 seconds later
      Pony.should_receive(:mail)
      get '/'
      Timecop.return
      
      Timecop.freeze(Time.at(1312299665)) # 93 seconds later
      Pony.should_receive(:mail)
      get '/'
      Timecop.return
      
      Timecop.freeze(Time.at(1312299696)) # 124 seconds later
      Pony.should_not_receive(:mail)
      get '/'
      Timecop.return
      
      ENV["MAX_INTERVAL"] = old_max_interval
      ENV["LAST_PING_RECEIVED_AT"] = old_lpra
      ENV["CONSECUTIVE_EMAILS"] = old_consecutive_emails
    end
    it "resets consecutive emails when within interval" do
      old_lpra = ENV["LAST_PING_RECEIVED_AT"]
      old_max_interval = ENV["MAX_INTERVAL"]
      old_consecutive_emails = ENV["CONSECUTIVE_EMAILS"]
      
      ENV["CONSECUTIVE_EMAILS"] = ""
      ENV["LAST_PING_RECEIVED_AT"] = "1312299572"
      ENV["MAX_INTERVAL"] = "30"
      
      Timecop.freeze(Time.at(1312299603)) # 31 seconds later
      Pony.should_receive(:mail)
      get '/'
      Timecop.return
      
      Timecop.freeze(Time.at(1312299634)) # 62 seconds later
      Pony.should_receive(:mail)
      get '/'
      Timecop.return
      
      Timecop.freeze(Time.at(1312299663)) # 91 seconds later
      get '/'
      ENV["CONSECUTIVE_EMAILS"].should == "0"
      Timecop.return
      
      ENV["MAX_INTERVAL"] = old_max_interval
      ENV["LAST_PING_RECEIVED_AT"] = old_lpra
      ENV["CONSECUTIVE_EMAILS"] = old_consecutive_emails
    end
  end
end