require 'openssl/cipher'
require 'active_support/rescuable'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash/indifferent_access'
require 'logger'

module HipaaCrypt
  class Encryptor
    include ActiveSupport::Rescuable

    rescue_from(Exception) { |error| Error.copy_and_raise error }

    # autoload :ContextualOptions, 'hipaa-crypt/encryptor/contextual_options'
    attr_reader :options, :cipher, :key

    def initialize(options={})
      options     = options.with_indifferent_access
      self.cipher = options.fetch :cipher, HipaaCrypt.config.cipher
      @key        = options.fetch :key, HipaaCrypt.config[:key]
      @options    = options
    end

    # @param string - the string to decrypt
    # @param iv - the iv to pass to the cipher
    def decrypt string
      with_rescue do
        setup_cipher __method__
        value = cipher.update(decode string) + cipher.final
        Callbacks.new(options[:after_load]).run deserialize value
      end
    end

    # Encrypt a value
    # @param value - the value to encrypt
    # @param iv - the iv to pass to the cipher
    def encrypt value # Should return [string, iv]
      with_rescue do
        value = serialize Callbacks.new(options[:before_encrypt]).run value
        setup_cipher __method__
        encode cipher.update(value) + cipher.final
      end
    end

    # @!attribute iv
    def iv
      @iv ||= options[:iv] || Base64.encode64(cipher.random_iv)
    end

    def decryptable?(value)
      !!decrypt(value)
    rescue Error
      false
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

    def setup_cipher mode
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

    def serialize(value)
      Marshal.dump(value)
    end

  end
end
