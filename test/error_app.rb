require 'sinatra'
require 'json'
require 'rack/response'

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
      set_resp_and_original_cookie env
      recreate attacked_cookie

      @resp.finish
    end

    private
    def set_resp_and_original_cookie env
      status, headers, body = @app.call(env)
      @resp = Rack::Response.new body, status, headers
      @original_cookie = @resp.headers['Set-Cookie']
    end

    def attacked_cookie
      self.send @attack
    end

    def recreate cookie
      @resp.headers['Set-Cookie'] = cookie.join(';')
      quality_check
    end

    def options
      x = split_session
      x.shift
      x
    end

    def split_session
      @original_cookie.split(';')
    end

    def session_data
      split_session.first.split('=').last
    end

    def key
      'rack.session='
    end

    def front
      options.unshift(key + 'front_attack' + session_data)
    end

    def back
      options.unshift(key + session_data + 'back_attack')
    end

    def both
      options.unshift(key + 'front_attack' + session_data + 'back attack')
    end

    def quality_check
      begin
        x = @original_cookie.split(';').count
        y = @resp.headers["Set-Cookie"].split(';').count
        raise unless x == y
      end
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

