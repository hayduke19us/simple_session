require 'sinatra'
require 'json'
require 'rack/request'

module ErrorApp 
  class Base < Sinatra::Base
    get '/' do
      {msg: 'This should fail before the request'}.to_json
    end
  end

  class MissingSecret < Base
    use SimpleSession::Session
  end

  class ShortSecret < Base
    use SimpleSession::Session, secret: SecureRandom.hex(1)
  end

  class Tamper
    def initialize app, options = {}
      @app = app
      @attack = options.fetch(:attack, 'front')
    end

    def call env
      set_request_and_original_cookie env

      if @original_cookie
        recreate attacked_cookie
      end

      @app.call env
    end

    private
    def set_request_and_original_cookie env
      @req = Rack::Request.new env
      # status, headers, body = @app.call(env)
      # @resp = Rack::Response.new body, status, headers
      @original_cookie = @req.cookies['rack.session']
    end

    # Returns appended or perpended cookie
    def attacked_cookie
      self.send @attack
    end

    def recreate cookie
      @req.cookies['rack.session'] = cookie
      # @resp.headers['Set-Cookie'] = cookie.join(';')
    end

    def front
      x = unpacked_original.unshift('front_attack')
      base x.join
    end

    def back
      x = unpacked_original.push('back_attack')
      base x.join
    end

    def both
      x = unpacked_original.push('back_attack')
      base x.unshift('front_attack').join
    end

    def unpacked_original
      @original_cookie.unpack('m0')
    end

    def base data
      [data].pack('m0')
    end

  end

  class AttackCookieFront < Base
    use Tamper
    use SimpleSession::Session, secret: SecureRandom.hex
  end

  class AttackCookieBack < Base
    use Tamper, attack: 'back'
    use SimpleSession::Session, secret: SecureRandom.hex
  end

  class AttackCookieBoth < Base
    use Tamper, attack: 'both'
    use SimpleSession::Session, secret: SecureRandom.hex
  end
end

