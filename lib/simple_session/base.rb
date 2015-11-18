require 'rack/request'
require 'securerandom'
require 'openssl'
require 'byebug'

module SimpleSession

  class Base

    attr_reader :request, :session

    def initialize app, options = {}
      @app          = app
      @key          = options.fetch :key, 'rack.session'
      @secret       = options.fetch :secret, get_secret_errors(options)
      @options_key  = options.fetch :options_key, 'rack.session.options'
      @default_opts = DEFAULT_OPTS.merge!(options)
    end

    def get_secret_errors options
      secret = options[:secret]
      missing_msg = %[
        SimpleSession requires a secret like this:
        use SimpleSession::Session, secret: 'some secret'
      ]

      short_msg  = %[
        SimpleSession require a secret with a minimum length of 32
        use SimpleSession::Session, secret: SecureRandom.hex(32)
      ]

      raise ArgumentError, missing_msg unless secret
      raise ArgumentError, short_msg   unless secret.length >= 32
    end

    def req_session
      request.cookies[@key] if request
    end

    def new_session_hash
      { session_id: SecureRandom.hex(32) }
    end

    def call env
      byebug
      # Decrypt request session and store it 
      extract_session env

      # Load session into app env
      load_environment env

      # Pass on request
      status, headers, body = @app.call env

      # Check session for changes and update
      update_options if options_changed?
      update_session if session_changed?

      # Encrypt and add session to headers
      add_session headers

      [status, headers, body]
    end

    def extract_session env
      begin
        @request = Rack::Request.new env
        @session = req_session ? decrypt(req_session) : new_session_hash
        session.merge!(options_hash)
        raise ArgumentError, "Unable to decrypt session" unless session

      rescue Exception => e
        @session = new_session_hash.merge!(options_hash)
        print e.message
      end

    end

    def options_hash
      o = session[:options] || OptionHash.new(@default_opts).opts
      { options: o }
    end

    def load_environment env
      env[@key] = session.dup
      env[@options_key] = session[:options].dup
    end

    def add_session headers
      cookie = Hash.new
      cookie.merge!(session.fetch(:options, @default_opts))
      cookie[:value] = encrypt session

      set_cookie_header headers, @key, cookie
    end

    def set_cookie_header headers, key, cookie
      Rack::Utils.set_cookie_header! headers, key, cookie
    end

    def update_options
      session[:options] = {options: OptionHash.new(request.session_options).opts}
    end

    def options_changed? 
      request.session_options != session[:options]
    end

    def session_changed?
      request.session != session
    end

    def update_session
      @session = request.session
    end

    def encrypt data
      # Serialize
      m = Marshal.dump data

      # Cipher
      c = load_cipher m

      # Sign
      h = hmac(cipher_key) + c

      # Encode Base64
      [h].pack('m')
    end

    def decrypt data
      # Decode Base64
      b = data.unpack('m').first

      # Parse Signature
      h    = b[0, 32]
      data = b[32..-1]

      if h == hmac(cipher_key).to_s
        # Decipher
        Marshal.load unload_cipher data
      else
        raise SecurityError
      end
    end

    def digest
      OpenSSL::Digest.new 'sha256', @secret
    end

    def hmac data
      OpenSSL::HMAC.digest digest, @secret, data
    end

    def new_cipher
      OpenSSL::Cipher::AES.new(256, :CBC)
    end

    def load_cipher marshaled_data
      cipher = new_cipher
      cipher.encrypt
      iv = cipher.random_iv
      cipher.iv  = iv
      cipher.key = cipher_key

      iv + cipher.update(marshaled_data) + cipher.final
    end

    def unload_cipher data
      cipher = new_cipher
      cipher.decrypt
      cipher.iv  = data[0, 16]
      cipher.key = cipher_key
      cipher.update(data[16..-1]) + cipher.final
    end

    def cipher_key
      hmac("A red, red fox has had three socks but all have holes" + @secret)
    end

    class OptionHash

      SANITATION = [:key, :secret, :options_key]

      def initialize args
        @opts = args
        process_request_options
        sanitize_opts
      end

      def opts
        @opts
      end

      def sanitize_opts
        @opts = sanitize @opts
      end

      def process_request_options
        begin
          p_time
        rescue => e
          puts e.message
        end
      end

      def p_time
        time = Time.now + @opts[:max_age].to_i
        @opts[:expires] = time if @opts[:max_age]
      end

      private
      def sanitize args
        SANITATION.each do |key|
          args.delete(key) if args[key]
        end
        args
      end

    end
  end
end
