require File.dirname(__FILE__) + '/spec_helper'

describe "Anacronism App" do
  include Rack::Test::Methods

  def app
    @app ||= Sinatra::Application
  end

  it "requires authentication" do
    get '/'
    last_response.status.should == 401
  end
  
  it "fails with bad authentication" do
    old_user = ENV["HTTP_USER"]
    old_pass = ENV["HTTP_PASSWORD"]
    ENV["HTTP_USER"] = "U"
    ENV["HTTP_PASSWORD"] = "p"
    
    authorize ENV["HTTP_USER"], ENV["HTTP_PASSWORD"] + "fail"
    get '/'
    last_response.body.should_not == "ACK"
    last_response.status.should == 401
    
    ENV["HTTP_USER"] = old_user
    ENV["HTTP_PASSWORD"] = old_pass
  end
  
  it "succeeds with authentication" do
    old_user = ENV["HTTP_USER"]
    old_pass = ENV["HTTP_PASSWORD"]
    ENV["HTTP_USER"] = "U"
    ENV["HTTP_PASSWORD"] = "p"
    
    authorize ENV["HTTP_USER"], ENV["HTTP_PASSWORD"]
    get '/'
    last_response.body.should == "ACK"
    last_response.status.should == 200
    
    ENV["HTTP_USER"] = old_user
    ENV["HTTP_PASSWORD"] = old_pass
  end
end