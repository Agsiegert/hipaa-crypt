module HipaaCrypt
  class MultiEncryptor

    attr_reader :options, :encryptors

    # Builds the default encryptor and encryptors in the chain with the merged local and global options.
    # @param options [Hash] The default encryptor with options and key chain.
    # @return [HipaaCrypt::MultiEncryptor] Returns the MultiEncryptor instance.
    def initialize( options = {} )
      @options = merge_defaults(options)
      @options[:encryptor] = HipaaCrypt::Encryptor if @options[:encryptor] == self.class
      @encryptors = build_encryptors
    end

    def active
      encryptors.first
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
      chain = options[:chain] || []
      options_without_chain = options.except(:chain)
      all_options = chain.map { |opts| options_without_chain.deep_merge(opts) }
      all_options.unshift options_without_chain if options_without_chain.has_key?(:key) && options_without_chain.has_key?(:encryptor)
      all_options.uniq.map { |opts| opts.delete(:encryptor) { HipaaCrypt::Encryptor }.new(opts) }
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

    def decryptable?(value)
      !!encryptors.first.decrypt(value)
    rescue Error
      false
    end

    module ConductorAdditions

      def encrypt(value)
        sub_conductors.first.encrypt value
      end

      def decrypt
        used_conductors = []
        sub_conductors = self.sub_conductors
        value = nil
        until value
          begin
            used_conductors << active_conductor = sub_conductors.shift
            value = active_conductor.send :decrypt
          rescue HipaaCrypt::Error => e
            retry unless sub_conductors.empty?
            raise e
          end
        end
        value
      end

      def decryptable?
        !!sub_conductors.first.decryptable?
      rescue Error
        false
      end

      def sub_conductors
        encryptor_from_options.encryptors.map do |e|
          Attributes::Conductor.new instance, e.options
        end
      end

    end

  end
end