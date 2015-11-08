$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simple_session'

require 'securerandom'
require 'json'

require 'minitest/autorun'
require 'minitest/pride'
require 'mintest/focus'

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



end
