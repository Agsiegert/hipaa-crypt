require 'logger'

module HipaaCrypt
  class Configuration
    attr_accessor :key
    attr_writer :cipher, :logger, :silent_re_encrypt

    # @!attribute cipher
    def cipher
      @cipher ||= { name: :AES, key_length: 256, mode: :CBC }
    end

    # @!attribute logger
    def logger
      begin
        @logger || (defined?(Rails) ? Rails.logger : Logger.new(STDOUT))
      end.dup
    end

    # @!attribute silent_re_encrypt
    def silent_re_encrypt
      !!@silent_re_encrypt
    end

  end
end