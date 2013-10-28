module HipaaCrypt
  class EncryptedObject

    attr_reader :iv, :value

    def initialize(options={})
      @iv    = options.delete(:iv) { raise ArgumentError, 'an iv is required' }
      @value = options.delete(:value) { raise ArgumentError, 'a value is required' }
    end

  end
end