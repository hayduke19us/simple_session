require "simple_session/version"
require "simple_session/base.rb"

# Options 
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# key          = options.fetch :key, 'rack.session'
# secret       = options[:secret]
# options_key  = options.fetch :options_key, 'rack.session.options'

module SimpleSession

  class Session < Base

    def initalize app, options={}
      super app, options
    end

    def call env
      super env
    end

  end

end
