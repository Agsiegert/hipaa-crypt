require 'openssl/cipher'
require 'active_support/rescuable'
require 'logger'

module HipaaCrypt
  class Encryptor
    include ActiveSupport::Rescuable

    rescue_from(Exception) { |error| Error.copy_and_raise error }

    autoload :ContextualOptions, 'hipaa-crypt/encryptor/contextual_options'
    attr_reader :options, :cipher

    def initialize(options={})
      options     = options.dup
      self.cipher = options.fetch :cipher, HipaaCrypt.config.cipher
      options[:key] ||= HipaaCrypt.config.key
      @options    = ContextualOptions.new(options)
    end

    def context
      options.context
    end

    def decrypt string, iv = options.get(:iv)
      with_rescue do
        setup_cipher __method__, iv
        value = cipher.update(decode string) + cipher.final
        Callbacks.new(options.raw_value :after_load).run deserialize value
      end
    end

    def encrypt value, iv = options.get(:iv) # Should return [string, iv]
      with_rescue do
        iv    ||= generate_iv
        value = serialize Callbacks.new(options.raw_value :before_encrypt).run value
        setup_cipher __method__, iv
        value = encode cipher.update(value) + cipher.final
        [value, iv]
      end
    end

    def key
      with_rescue do
        options.get(:key) { raise(ArgumentError, 'you must provide a key to encrypt an attribute') }
      end
    end

    def with_context(context)
      dup.tap { |encryptor| encryptor.instance_variable_set :@options, options.with_context(context) }
    end

    protected

    def cipher=(val)
      @cipher = OpenSSL::Cipher.new val.is_a?(Hash) ? cipher_string_from_hash(val) : val
    end

    private

    def with_rescue(&block)
      yield
    rescue Exception => exception
      rescue_with_handler(exception) || raise(exception)
    end

    def setup_cipher(mode, iv)
      cipher.reset
      cipher.send(mode)
      cipher.key = key
      cipher.iv  = iv
    end

    def cipher_string_from_hash(hash)
      hash.values_at(:name, :key_length, :mode).join('-').downcase
    end

    def decode(value)
      value.unpack('m').first
    end

    def deserialize(value)
      Marshal.load(value)
    end

    def encode(value)
      [value].pack('m')
    end

    def generate_iv
      SecureRandom.base64(44)
    end

    def serialize(value)
      Marshal.dump(value)
    end

  end
end