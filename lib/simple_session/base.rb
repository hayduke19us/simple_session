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
      @secret       = options[:secret]
      @cipher_key   = cipher_key
      @options_key  = options.fetch :options_key, 'rack.session.options'
      @default_opts = options
    end

    def req_session
      request.cookies[@key] if request
    end

    def req_options
      session[:options] if session
    end

    def clear_session
      @session = new_session_hash
      @options = {options: OptionHash.new(@default_opts).opts}
    end

    def time_expired?
      req_options && req_options[:expire] && req_options[:expire] <= Time.now
    end

    def new_session_hash
      { session_id: SecureRandom.hex(32) }
    end

    def call env
      # Decrypt request session and store it 
      extract_session env

      original_opts = @options[:options].dup

      # Process options
      clear_session if time_expired?

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

    def update_options
      @options = {options: OptionHash.new(@options[:options]).opts}
    end

    def options_changed? original
      original != @options[:options]
    end

    # If the session is nil create a new one
    # If the session is unable to be decrypted throw an
    # error and create a new one.
    # encrypted data is not allowed in the app env
    def extract_session env
      begin
        @request = Rack::Request.new env
        @session = req_session ? decrypt(req_session) : new_session_hash

        unless @session
          raise ArgumentError, "Unable to decrypt session  #{caller[0]}"
        end

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
      cookie[:value]   = session[:value] || session
      cookie[:expires] = @options[:options][:expire]
      set_cookie_header headers, @key, encrypt(cookie.merge!(@options))
    end

    def set_cookie_header headers, key, cookie
      Rack::Utils.set_cookie_header! headers, key, cookie
    end

    def options_hash
      o = session[:options] || OptionHash.new(@default_opts).opts
      { options: o }
    end

    def encrypt data
      begin
        if data.is_a? Hash
          # Serialize
          m = Marshal.dump data

          # Cipher
          c = load_cipher m

          # Base64
          [c].pack('m')
        else
          raise ArgumentError, "Internal session data must be a hash"
        end
      rescue => e
        puts e.message
      end
    end

    def decrypt data
      begin
        if data.is_a? String
          # Decode Base64
          b = data.unpack('m').first

          # Decipher
          c = unload_cipher b

          # Deserialize
          Marshal.load c
        else
          raise ArgumentError, "External session data must be a string."
        end
      rescue => e
        puts e.message
      end
    end

    def digest
      OpenSSL::Digest.new 'sha256', @secret
    end

    def hmac data
      OpenSSL::HMAC.digest digest, @key, data
    end

    def new_cipher
      OpenSSL::Cipher::AES.new(256, :CBC)
    end

    def load_cipher marshaled_data
      cipher = new_cipher
      cipher.encrypt
      iv = cipher.random_iv
      cipher.iv  = iv
      cipher.key = @cipher_key

      iv + cipher.update(marshaled_data) + cipher.final
    end

    def unload_cipher data
      cipher = new_cipher
      cipher.decrypt
      cipher.iv  = data[0, 16]
      cipher.key = @cipher_key
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
        set_instance_variables
        create_readers
      end

      def opts
        @opts
      end

      def create_reader name 
        self.class.send(:define_method, name, &Proc.new)
      end

      def create_readers
        @opts.keys.each do |k|
          create_reader(k) { instance_variable_get "@#{k}"}
        end
      end

      def set_instance_variables
        @opts.each { |k, v| instance_variable_set "@#{k.to_s}", v}
      end

      def process_request_options
        begin
          p_time
        rescue => e
          puts e.message
        end
      end

      def p_time
        @opts[:expire_after] ||= default_time
        @opts[:expire] = Time.now + @opts[:expire_after].to_i if @opts[:expire_after]
      end

      private
      def sanitize args
        dup_args = args
        SANITATION.each do |key|
          dup_args.delete(key) if args[key]
        end
        dup_args
      end

      def default_time
        60 * 60 * 2
      end

    end

  end

end

