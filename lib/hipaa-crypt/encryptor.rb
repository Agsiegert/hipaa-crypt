require 'base64'
require 'openssl/cipher'

module HipaaCrypt
  class Encryptor

    autoload :Normalizer, 'hipaa-crypt/encryptor/normalizer'
    attr_reader :options, :cipher, :key

    def initialize(options={}, context = self)
      options     = options.dup
      self.cipher = options.delete(:cipher) { { name: :AES, key_length: 256, mode: :CBC } }
      @key        = options.delete(:key) { raise ArgumentError, 'you must provide a key to encrypt an attribute' }
      @options    = Normalizer.new(context).normalize_options(options)
    end

    def encrypt(value)
      value = run_before_hooks(value)
      cipher.encrypt
      cipher.key = key
      iv = generate_iv
      cipher.iv  = iv
      dump_and_encode cipher.update(value) + cipher.final, iv
    end

    def decrypt(string)
      encrypted_object = decode_and_load string
      cipher.decrypt
      cipher.key = key
      cipher.iv  = encrypted_object.iv
      value      = cipher.update(encrypted_object.value) + cipher.final
      run_after_hooks(value)
    end

    protected

    def cipher=(val)
      @cipher = OpenSSL::Cipher.new val.is_a?(Hash) ? cipher_string_from_hash(val) : val
    end

    private

    def cipher_string_from_hash(hash)
      hash.values_at(:name, :key_length, :mode).join('-').downcase
    end

    def decode_and_load(string)
      Marshal.load Base64.decode64 string
    end

    def dump_and_encode(string, iv)
      Base64.encode64 Marshal.dump EncryptedObject.new(value: string, iv: iv)
    end

    def generate_iv
      options.fetch :iv, OpenSSL::Random.random_bytes(cipher.iv_len)
    end

    def invoke_hook_on_value(hook, value)
      case hook
      when Symbol
        value.send(value)
      when Proc
        hook.call(value)
      else
        raise ArgumentError, 'hooks may only be symbols or procs'
      end
    end

    def run_after_hooks(value)
      run_hooks options[:after_load], value
    end

    def run_before_hooks(value)
      run_hooks options[:before_encrypt], value
    end

    def run_hooks(hooks, value)
      hooks = [hooks].flatten.compact
      hooks.reduce(value) do |hook, v|
        invoke_hook_on_value hook, v
      end
    end

  end
end