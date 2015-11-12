require 'sinatra'
require 'json'

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
end

