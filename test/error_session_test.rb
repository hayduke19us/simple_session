require 'test_helper'
require_relative 'error_app'

class ErrorSessionTest < Minitest::Test
  include Rack::Test::Methods

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
end
