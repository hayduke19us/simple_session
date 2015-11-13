require 'sinatra'
require 'json'
require 'byebug'
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
    def initialize app
      @app = app
    end

    def call env
      status, headers, body = @app.call(env)
      resp = Rack::Response.new body, status, headers
      x = resp.headers["Set-Cookie"].split(';')
      y = x.first.split('=').last
      x.shift
      x.unshift('rack.session=' + 'hello' + y)
      final = x.join(';')
      resp.headers['Set-Cookie'] = final

      resp.finish
    end
  end

  class ChangeHeader < Base
    use Tamper
    use SimpleSession::Session, secret: SecureRandom.hex
  end
end

