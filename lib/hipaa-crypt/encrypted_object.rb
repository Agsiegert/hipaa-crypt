module HipaaCrypt
  class EncryptedObject

    attr_reader :iv, :value

    def initialize(value, iv)
      @value = value
      @iv    = iv
    end

  end
end