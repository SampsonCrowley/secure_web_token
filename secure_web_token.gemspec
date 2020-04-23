$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "secure_web_token/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "secure_web_token"
  s.version     = SecureWebToken::VERSION
  s.authors     = ["Sampson Crowley"]
  s.email       = ["sampsonsprojects@gmail.com"]
  s.homepage    = "https://github.com/SampsonCrowley/secure_web_token"
  s.summary     = "Secure defaults for encrypted JWTs"
  s.description = "Generate, encrypt, and decrypt signed JSON web tokens"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "jwt", "~> 2.2"
  s.add_dependency "jwe", "~> 0.4"

  s.add_development_dependency "activesupport", "~> 6.0"
  s.add_development_dependency "coerce_boolean", "~> 0.1"
  s.add_development_dependency "minitest", "~> 5.1"
  s.add_development_dependency 'minitest-reporters', "~> 1.4"
  s.add_development_dependency "rake", "~> 13.0"
end
