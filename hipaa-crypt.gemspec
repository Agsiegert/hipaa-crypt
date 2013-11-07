# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hipaa-crypt/version'

Gem::Specification.new do |spec|

  spec.name        = "hipaa-crypt"
  spec.version     = HipaaCrypt::VERSION
  spec.authors     = ["Jason Waldrip"]
  spec.email       = ["jason@waldrip.net"]
  spec.description = "PORO attribute encryption, with ORM support"
  spec.summary     = "Provide a universal wrapper for encrypting data in plain old ruby objects."
  spec.homepage    = "https://github.com/Healthagen/hipaa-crypt"
  spec.license     = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  spec.add_dependency "activesupport", ">= 3.2.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "appraisal", "1.0.0.beta1"

  # For creating dummy objects
  spec.add_development_dependency "faker"
  spec.add_development_dependency "sqlite3"

  # For Testing Some ORMS
  spec.add_development_dependency "activerecord", ">= 3.2.0"

end
