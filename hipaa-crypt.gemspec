# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hipaa-crypt/version'

Gem::Specification.new do |spec|
  spec.name          = "hipaa-crypt"
  spec.version       = HipaaCrypt::VERSION
  spec.authors       = ["Jason Waldrip"]
  spec.email         = ["jason@waldrip.net"]
  spec.description   = "PORO attribute encryption, with ORM support"
  spec.summary       = "Provide a universal wrapper for encrypting data in plain old ruby objects."
  spec.homepage      = "https://github.com/Healthagen/hipaa-crypt"
  spec.license       = "Copyright, iTriage LLC"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "pry"

  # For Testing Some ORMS
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "mongoid"
  spec.add_development_dependency "datamapper"

end