# SimpleSession

This is a drop in replacement for rack session. By default
the session cookie is encrypted in AES-256-CBC and requires a secret
which is recommended to be kept in an .env file or something similar. 

[install-sect](Installation) 
* [Usage][usage-sect]
	* [Overview][overview-sect]
	* [Default Options][default-sect]
	
[install-sect](#### Installation )

Add this line to your application's Gemfile:

```ruby
gem 'simple_session'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_session

## Usage [usage-sect]
Full examples are in the *test/simple_session_test.rb* and 
*test/simple_app.rb*.

#### Overview [overview-sect]
SimpleSession is a simple Middleware that processes the session cookie
with 5 steps.

1. Extract the session from the request if there is one. If there is no session 
create a new one that looks like this:

```ruby
{ session_id: 'some secret id' }
```

2. Load the session data into the app environment so they are accessible with racks request methods like this:

```ruby
get '/'
request.session 
  session
  request.session_options
end
```
				
3. Clear the session if the time has expired and create a new one.

4. Update the options if they have been changed like this.  

```ruby
# This changes the session to expire one minute after 
# the current time. 
get '/'  
  request.session_options[:expire_after] = 60
end
```

5. Create the new session cookie, encrypt it and return the response. 

#### Default Options [default-sect]

* secret: nil
* key: 'rack.session'
* expire_after: 7200

The following is a simple example. The only **required argument is :secret**.

```ruby
require 'sinatra'
require 'simple_session'

class SimpleApp < Sinatra::Base

  use SimpleSession::Session, secret: 'Your Secret'

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

**Write a test** and go for it.

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/simple_session. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

