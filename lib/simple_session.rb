require "simple_session/version"
require "simple_session/base.rb"

module SimpleSession
  DEFAULT_OPTS = {
    max_age: 7200 ,
    domain: nil,
    path: '/',
    http_only: false,
    secure: false,
  }

  class Session < Base

    def initalize app, options={}
      super app, options
    end

    def call env
      super env
    end

  end

end
