require 'hipaa-crypt'
require 'pry'

HipaaCrypt.config[:logger] = Logger.new STDOUT

puts HipaaCrypt.config.logger

class Foo
  include HipaaCrypt::Attributes
  encrypt :foo, key: SecureRandom.hex, cipher: 'aes-256-cbc'
end

f = Foo.new
f.foo = 'bar'

binding.pry