# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simple_session/version'

Gem::Specification.new do |spec|
  spec.name          = "simple_session"
  spec.version       = SimpleSession::VERSION
  spec.authors       = ["hayduke19us"]
  spec.email         = ["hayduke19us@gmail.com"]

  spec.summary       = %q{A simple middleware providing rack with a session cookie.}
  spec.description   = %q{Provides the a light version of racks session options 
                          and honers rack's naming conventions. HMAC AES-128-CBC 
                          encryption included}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "sinatra"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "minitest-focus"

  spec.add_runtime_dependency "rack"
end
