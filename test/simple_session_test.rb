require 'test_helper'
require 'rack/test'
require 'timecop'
require_relative 'simple_app'

# TestHelpers methods
# secure_rand, returns SecureRandom 32 byte hex
# response,    returns last_response
# body,        if the body is a string parse it else return response.body
# res_session, return the parsed inner elements of session if any
# res_opts,    same as #res_session but for options
# encrypted_cookie_session, original headers parsed to rack.session value

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
    refute body['session']['user_id']
  end

  def test_the_response_session_is_encrypted
    get '/signin'
    get '/'
    uri  = URI.decode encrypted_cookie_session
    base = uri.unpack('m').first

    assert_raises TypeError, "response session can not be decoded with Base64" do
      Marshal.load base
    end 
  end

  def test_session_after_the_options_were_changed
    # First request made a day ago, with expire_after: set to + 10 seconds
    # SimpleSession::Session, secret: SecureRandom.hex(32), expire_after: 10
    Timecop.freeze(Time.now - (60 * 60 * 24)) do
      get '/signin'
      assert_match(/!Green/, body['user_id'])

      # Changes expire_after to 2 days from now
      post '/options', max_age: 60 * 60 * 48
      assert_equal 10,  body['old'].to_i
      assert_equal 172800, body['new'].to_i
    end

    get '/expire'
    assert_match(/!Green/, res_session['user_id'])
  end

end
