require 'sinatra'
require 'sinatra/json'

class SimpleApp < Sinatra::Base
  # disable: show_exceptions

  # The expire argument is added to current server time as seconds
  use SimpleSession::Session, secret: SecureRandom.hex(32), expire_after: 1

  def authenticated? &block
    if session[:user_id] == '!Green3ggsandHam!'
      status 200
      json yield
    else
      status 401
      json msg: "You must sign in"
    end
  end

  def user_id_hash
    {user_id: session[:user_id]}
  end

  get '/' do
    authenticated? do
      user_id_hash
    end
  end

  get '/signin' do
    session[:user_id] ? "Signed in" : session[:user_id] = '!Green3ggsandHam!'
    json user_id: session[:user_id]
  end

  get '/signout' do
    authenticated? do
      session.clear
      user_id_hash
    end
  end

  # List all the options for expire, used as an expired request test
  get '/expire' do 
    json session: session.to_json
  end

  post '/options' do
    old_expire = request.session_options[:expire_after]
    request.session_options[:expire_after] = params[:expire_after]

    json old: old_expire, new: request.session_options[:expire_after]
  end

end

