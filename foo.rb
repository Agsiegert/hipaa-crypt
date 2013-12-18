require 'hipaa-crypt'
require 'pry'

HipaaCrypt.config[:logger] = Logger.new STDOUT

puts HipaaCrypt.config.logger

class Foo
  include HipaaCrypt::Attributes

  # attr_accessor :encrypted_foo

  encrypt :foo, key: SecureRandom.hex, cipher: 'aes-256-cbc'

  def foo=(val)
    @my_amazing_foo = val
  end

  def foo
    @my_amazing_foo
  end

end

f = Foo.new
f.foo = 'bar'

binding.pry