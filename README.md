# SimpleSession
![build-status](https://travis-ci.org/hayduke19us/simple_session.svg?branch=master)

This is a drop in replacement for rack session. By default
the session cookie is encrypted in AES-256-CBC and requires a secret
which is recommended to be kept in an .env file or something similar. 

<a href='#install-sect'><h4>Installation</h4></a>

<a href='#usage-sect'><h4>Usage</h4></a>

<a href='#default-sect'><h4>Default Options</h4></a>

<a href='#overview-sect'><h4>Overview</h4></a>

<a href='#overview-sect'><h4>Overview</h4></a>
	
<h2 id='install-sect'>Installation</h2>

Add this line to your application's Gemfile:

```ruby
gem 'simple_session'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_session
    
<h2 id='usage-sect'>Usage</h2>
Full examples are in the *test/simple_session_test.rb* and 
*test/simple_app.rb*. It's just a middleware so throw it on top of the stack.

```ruby
use SimpleSession::Session, secret: SecureRandom.hex
```
**NOTE:** `:secret` must be 32 chars long.

<h4 id='default-sect'>Default Options</h4>

```ruby 
secret: nil
key: 'rack.session', 
options_key: 'rack.session.options' ,
max_age: 172800,
path: '/',
domain: 'nil',
secure: false,
http_only: false
```
**NOTE:** For persistent options `:max_age` is excepted and the default is 2 days. 
Because there are still IE versions that don't support max-age we inject both **max-age** and **expires** into the cookie and let the browser handle it.

The following is a simple example. The only **required argument is :secret**.

```ruby
require 'sinatra'
require 'simple_session'

class SimpleApp < Sinatra::Base

  SECRET = SecureRandom.hex
  use SimpleSession::Session, secret: SECRET

  get '/signin' do
    if session[:user_id] 
      "Already Signed in"
    else
      session[:user_id] = '!Green3ggsandHam!'
      "Id:  #{ session[:user_id] }"
    end
  end

end
```

<h4 id='overview-sect'>Overview</h4>
SimpleSession is a simple Middleware that processes the session cookie
with 4 steps.

*  Extract the session from the request if there is one. If there is no session 
create a new one that looks like this:

```ruby
{ session_id: 'some secret id' }
```
* Load the session data into the app environment so they are accessible with racks request methods like this:
```ruby
get '/'
  request.session 
  session
  request.session_options
end
```
* Update the options if they have been changed like this.  

```ruby
# This changes the session to expire one minute after 
# the current time. 
get '/'  
  request.session_options[:max_age] = 60
end
```

* Create the new session cookie, encrypt it and return the response. 


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

**Write a test** and go for it.

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/simple_session. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

