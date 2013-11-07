require 'simplecov'
require 'coveralls'

require 'rspec/autorun'
require 'bundler/setup'
require 'pry'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter "/spec/"
end

require 'hipaa-crypt'

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

HipaaCrypt.config do |c|
  c.logger            = Logger.new('/dev/null')
  c.silent_re_encrypt = true
end

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.alias_example_to :fit, focus: true
  config.alias_example_to :fits, focus: true
end
