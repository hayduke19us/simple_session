require 'test_helper'
require_relative 'error_app'

class ErrorSessionTest < Minitest::Test
  include Rack::Test::Methods
  include TestHelpers

  def app
    @app
  end

  def test_missing_secret_raises_an_arg_error
    @app = ErrorApp::MissingSecret
    assert_raises ArgumentError do
      get '/'
    end
  end

  def test_too_short_secret_raises_an_arg_error
    @app = ErrorApp::ShortSecret
    assert_raises ArgumentError do
      get '/'
    end
  end

  def test_if_hmac_fails_a_new_session_is_created_and_request_continues
    @app = ErrorApp::AttackCookieFront
    get '/'
    assert response.body['msg']
    assert last_response.ok?
  end

  def test_when_attacked_from_the_front_security_error
    @app = ErrorApp::AttackCookieFront
    assert_security_error
  end

  # TODO Back is not safe will create signature on both sides
  def test_when_attacked_from_the_back_security_error
    @app = ErrorApp::AttackCookieBack
    assert_security_error
  end

  focus
  def test_when_attacked_from_both_sides_security_error
    @app = ErrorApp::AttackCookieBoth
    assert_security_error
  end

  def assert_security_error
    # We make an initial request to populate the session
    get '/'
    assert_output 'SecurityError' do
      get '/'
    end
  end

end
