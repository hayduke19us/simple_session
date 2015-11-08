require 'test_helper'
require 'sinatra'
require 'sinatra/json'
require 'rack/test'
require 'timecop'

class SimpleApp < Sinatra::Base
  # disable: show_exceptions

  # The expire argument is added to current server time as seconds
  use SimpleSession::Session, secret: SecureRandom.hex(32), expire: 1
  before do 
  end

  def authenticated? &block
    if session[:user_id] == '!Green3ggsandHam!'
      status 200
      json yield
    else
      status 401
      json msg: "You must sign in"
    end
  end

  def user_id_hash
    {user_id: session[:user_id]}
  end

  get '/' do
    authenticated? do
      user_id_hash
    end
  end

  get '/signin' do
    session[:user_id] ? "Signed in" : session[:user_id] = '!Green3ggsandHam!'
    json user_id: session[:user_id]
  end

  get '/signout' do
    authenticated? do
      session.clear
      user_id_hash
    end
  end

  # Change expire to 10 seconds from now
  get '/expire' do 
    hash = { session: session.inspect, 
      options: request.session_options.inspect,
      timeNow: Time.now
    }
    json hash
  end

end

class SimpleSessionTest < Minitest::Test
  include Rack::Test::Methods
  include TestHelpers

  def app
    SimpleApp
  end

  def test_that_it_has_a_version_number
    refute_nil ::SimpleSession::VERSION
  end

  def test_we_have_access_to_session_in_env
    get '/signin'
    assert_equal 200, response.status
    assert_equal "!Green3ggsandHam!", body['user_id']
  end

  def test_when_signed_in_we_get_a_response_of_session_data
    get '/signin'
    get '/'
    assert_equal 200, response.status
    assert_equal "!Green3ggsandHam!", body['user_id']
  end

  def test_when_not_signed_in_we_get_a_401
    get '/'
    assert_equal 401, response.status
    assert_equal "You must sign in", body['msg']
  end

  def test_when_we_sign_out_our_session_is_cleared
    get '/signin'
    get '/signout'
    assert_equal 200, response.status
    refute body['user_id']
  end

  def test_expired_session_id_is_recreated_and_session_is_cleared
    Timecop.freeze(Time.now - (60 * 60 * 24)) do
      get '/signin'
      assert_match(/\A!Green/, body['user_id'])
    end

    get '/expire'
    refute body['user_id']
  end
end
