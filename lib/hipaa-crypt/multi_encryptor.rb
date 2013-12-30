module HipaaCrypt
  class MultiEncryptor

    attr_reader :merged_options, :encryptors

    def initialize( options = {} )
      @merged_options = merge_defaults(options)
      @merged_options[:encryptor] = HipaaCrypt::Encryptor if @merged_options[:encryptor] == self.class
      @encryptors = build_encryptors
    end

    def merge_defaults(options)
      default_options = HipaaCrypt.config.deep_merge(options)
      local_defaults  = default_options.except :defaults
      local_defaults.deep_merge!( default_options.fetch :defaults, {} )
    end

    def build_encryptors
      chain = merged_options[:chain] || []
      all_options = ([merged_options] + chain.map {|opts| merged_options.deep_merge(opts) }).uniq
      all_options.map { |opts| opts.delete(:encryptor) { HipaaCrypt::Encryptor }.new(opts) }
    end

    def encrypt(*args)
      encryptors.first.send :encrypt, *args
    end

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