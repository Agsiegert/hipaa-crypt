require 'openssl/cipher'

module HipaaCrypt
  class AttrEncryptedEncryptor < Encryptor

    private

    def encode(value)
      options[:encode] ? super(value) : value
    end

    def decode(value)
      options[:encode] ? super(value) : value
    end

    def deserialize(value)
      options[:marshal] ? super(value) : value
    end

    def serialize(value)
      options[:marshal] ? super(value) : value
    end

    def setup_cipher mode
      iv = options[:iv]
      if iv.to_s.length > 0
        super mode
      else
        cipher.reset
        cipher.send(mode)
        cipher.pkcs5_keyivgen(key)
      end
    end

    def generate_iv
      nil
    end

  end
end