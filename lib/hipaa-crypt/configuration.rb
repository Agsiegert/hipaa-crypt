require 'logger'

module HipaaCrypt
  class Configuration
    attr_accessor :key
    attr_writer :cipher, :logger

    def cipher
      @cipher ||= {name: 'AES', key_length: 256, mode: 'CBC'}
    end

    def logger
      @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end
  end
end