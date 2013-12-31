module HipaaCrypt
  class MultiEncryptor

    attr_reader :merged_options, :encryptors

    # Builds the default encryptor and encryptors in the chain with the merged local and global options.
    # @param options [Hash] The default encryptor with options and key chain.
    # @return [HipaaCrypt::MultiEncryptor] Returns the MultiEncryptor instance.
    def initialize( options = {} )
      @merged_options = merge_defaults(options)
      @merged_options[:encryptor] = HipaaCrypt::Encryptor if @merged_options[:encryptor] == self.class
      @encryptors = build_encryptors
    end

    # Merges the global and local options appropriately.
    # @param options [Hash] The default encryptor with options and key chain.
    # @return [Hash] Returns the merged global and local options.
    def merge_defaults(options)
      default_options = HipaaCrypt.config.deep_merge(options)
      local_defaults  = default_options.except :defaults
      local_defaults.deep_merge!( default_options.fetch :defaults, {} )
    end

    # Initializes new instances of the default encryptor as well as the encryptors in the key chain
    # with the merged options.
    # @return [Array] Returns an array with all the initizliaed encryptors.
    def build_encryptors
      chain = merged_options[:chain] || []
      all_options = ([merged_options] + chain.map {|opts| merged_options.deep_merge(opts) }).uniq
      all_options.map { |opts| opts.delete(:encryptor) { HipaaCrypt::Encryptor }.new(opts) }
    end

    # Encrypts the given attribute with the first encryptor in the encryptors array.
    # @param *args [attribute] Takes an arbitrary number of attributes to encrypt.
    # @return [encrypted_value] Returns the encrypted attribute.
    def encrypt(*args)
      encryptors.first.send :encrypt, *args
    end

    # Tries to decrypt the encrypted value with each encryptor unitl it is able to successfully decrypt the value.
    # @param *args [attribute] Takes an arbitrary number of attributes to decrypt.
    # @return [decrypted_value] Returns the decrypted value. 
    def decrypt(*args)
      encryptors = self.encryptors.dup
      value = nil
      until value
        begin
          value = encryptors.shift.send :decrypt, *args
        rescue HipaaCrypt::Error::OpenSSLCipherCipherError => e
          retry unless encryptors.empty?
          raise e
        end
      end
      value
    end
  end
end