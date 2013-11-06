require 'openssl/cipher'

module HipaaCrypt
  class AttrEncryptedEncryptor < Encryptor

    def decrypt string, iv = options.get(:iv)
      setup_cipher __method__, iv
      encrypted_value = options.get(:encode) ? (decode string) : string
      value      = cipher.update(encrypted_value) + cipher.final
      value_for_callbacks = (options.get(:marshal) ? (deserialize value) : value)
      Callbacks.new(options.raw_value :after_load).run value_for_callbacks
    rescue => e
      logger.error "Decrypt Error => #{e.class}: #{e.message}"
      raise e
    end

    def encrypt value, iv = options.get(:iv) # Should return [string, iv]
      processed_value = Callbacks.new(options.raw_value :before_encrypt).run value
      value = options.get(:marshal) ? serialize(processed_value) : processed_value
      setup_cipher __method__, iv
      encrypted_value = cipher.update(value) + cipher.final
      value = options.get(:encode) ? (encode encrypted_value) : encrypted_value
      [value, iv]
    rescue => e
      logger.error "Encrypt Error => #{e.class}: #{e.message}"
      raise e
    end

    private

    def setup_cipher(mode, iv)
      cipher.reset
      cipher.send(mode)
      if iv.to_s.length > 0
        cipher.key = key
        cipher.iv  = iv
      else
        cipher.pkcs5_keyivgen(key)
      end
    end

  end
end