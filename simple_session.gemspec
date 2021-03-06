# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simple_session/version'

Gem::Specification.new do |spec|
  spec.name          = "simple_session"
  spec.version       = SimpleSession::VERSION
  spec.authors       = ["hayduke19us"]
  spec.email         = ["hayduke19us@gmail.com"]

  spec.summary       = %q{A simple middleware providing rack with an
                          encrypted session cookie.}
  spec.description   = %q{Provides an AES-256-CBC encrypted session cookie signed
                          with an HMAC digest in a double ended manor. 
                          Cookie options include max-age, path, domain, http-only,
                          and secure. Honors Rack's
                          methods like session and request.session_options}
  spec.homepage      = "https://github.com/hayduke19us/simple_session"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "sinatra"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "minitest-focus"

  spec.add_runtime_dependency "rack"
end
