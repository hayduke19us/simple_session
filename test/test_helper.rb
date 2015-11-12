$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simple_session'

require 'securerandom'
require 'json'
require 'rack/test'

require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/focus'

module TestHelpers

  def secure_rand
    SecureRandom.hex(32)
  end

  def response
    last_response
  end

  def body
    response.body.is_a?(String) ? JSON.parse(response.body) : response.body
  end

  def res_session
    JSON.parse body['session'] if body['session']
  end

  def res_opts
    JSON.parse body['options'] if body['options']
  end

  def encrypted_cookie_session
    response.headers["Set-Cookie"].split(";").first.split('=').last
  end


end
