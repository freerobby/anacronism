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
  end
end