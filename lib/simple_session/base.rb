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

    def req_options
      session[:options] if session
    end

    def new_session_hash
      { session_id: SecureRandom.hex(32) }
    end

    def call env
      # Decrypt request session and store it 
      extract_session env

      original_opts = @options[:options].dup

      # Load session into app env
      load_environment env

      # Pass on request
      status, headers, body = @app.call env

      # Check session for changes and update options
      update_options if options_changed? original_opts

      # Encrypt and add session to headers
      add_session headers

      [status, headers, body]
    end

    private
    def extract_session env
      begin
        @request = Rack::Request.new env
        @session = req_session ? decrypt(req_session) : new_session_hash

        raise ArgumentError, "Unable to decrypt session" unless @session

      rescue => e
        @session = new_session_hash
        puts e.message
      end

      @options = options_hash
    end

    def load_environment env
      env[@key] = session[:value] || session
      env[@options_key] = @options[:options]
    end

    def add_session headers
      cookie = Hash.new
      cookie[:value] = encrypt session.merge!(@options)
      cookie = cookie.merge!(@options[:options])

      set_cookie_header headers, @key, cookie
    end

    def set_cookie_header headers, key, cookie
      Rack::Utils.set_cookie_header! headers, key, cookie
    end

    def options_hash
      o = session[:options] || OptionHash.new(@default_opts).opts
      { options: o }
    end

    def update_options
      @options = {options: OptionHash.new(@options[:options]).opts}
    end

    def options_changed? original
      original != @options[:options]
    end

    def encrypt data
      # Serialize
      m = Marshal.dump data

      # Cipher
      c = load_cipher m

      # Encode Base64
      [c].pack('m')
    end

    def decrypt data
      # Decode Base64
      b = data.unpack('m').first

      # Decipher
      c = unload_cipher b

      # Deserialize
      Marshal.load c
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
      hmac("A red, red fox has had three socks but all have holes")
    end

    class OptionHash

      SANITATION = [:key, :secret, :options_key]

      def initialize args
        @opts = sanitize args.dup
        process_request_options
      end

      def opts
        @opts
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
