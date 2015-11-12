require 'test_helper'
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

  def test_expired_session_is_cleared
    get '/signin'
    assert_match(/\A!Green/, body['user_id'])

    Timecop.freeze(Time.now + 60 ) do
      get '/expire'
      refute res_session['user_id']
    end
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

  def session_accepts_changes_from_the_controller_and_applies_them
    get '/signin'
    assert_match(/!Green/, body['user_id'])

    post '/options', max_age: 60 * 60 * 48
    assert_equal 10,  body['old'].to_i, "old max-age"
    assert_equal 172800, body['new'].to_i, "new max-age"

    Timecop.freeze(Time.now  + (60 * 60 * 24)) do
      get '/expire'
      assert_match(/!Green/, res_session['user_id'])
    end
  end

  def test_session_is_not_renewed_each_request_and_the_options_are_persistant
    get '/expire'
    first = Time.parse(res_session['expires'])

    get '/expire'
    second = Time.parse(res_session['expires'])

    assert_equal first, second

    Timecop.freeze(Time.now + 10) do
      current = Time.now
      get '/expire'

      last = Time.parse(res_session['expires'])
      diff = last - current

      assert diff >= 9 && diff < 11
      refute_equal first, last
    end
  end

end
