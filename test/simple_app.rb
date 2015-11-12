require 'sinatra'
require 'json'

class SimpleApp < Sinatra::Base
  # disable: show_exceptions
  SECRET = SecureRandom.hex

  # The expire argument is added to current server time as seconds
  use SimpleSession::Session, secret: SECRET, max_age: 10

  def authenticated? &block
    if session[:user_id] == '!Green3ggsandHam!'
      status 200
      yield
    else
      status 401
      {msg: "You must sign in"}.to_json
    end
  end

  def user_id_hash
    {user_id: session[:user_id]}.to_json
  end

  get '/' do
    authenticated? do
      user_id_hash
    end
  end

  get '/signin' do
    session[:user_id] = '!Green3ggsandHam!'
    user_id_hash
  end

  get '/signout' do
    authenticated? do
      session.clear
      user_id_hash
    end
  end

  # List all the options for expire, used as an expired request test
  get '/expire' do 
    {session: session.merge(request.session_options).to_json}.to_json
  end

  post '/options' do
    sanitize = ['expires', 'max_age', 'path', 'domain', 'secure', 'http_only']

    hashed_params = Hash.new
    params.each { |k, v| hashed_params[k.to_sym] = v if sanitize.include?(k)}

    old_expire = request.session_options[:max_age]

    request.session_options.merge!(hashed_params)

    {old: old_expire, new: request.session_options[:max_age]}.to_json
  end

end

