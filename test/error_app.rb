require 'sinatra'

module ErrorApp 
  class Base < Sinatra::Base
    get '/' do
      json msg: 'This should fail before the request'
    end
  end

  class MissingSecret < Base
    use SimpleSession::Session
  end

  class ShortSecret < Base
    use SimpleSession::Session, secret: SecureRandom.hex(1)
  end
end

