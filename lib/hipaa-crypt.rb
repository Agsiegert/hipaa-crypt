require 'active_support/all'
require 'bundler/setup'

module HipaaCrypt

  autoload :Callbacks, 'hipaa-crypt/callbacks'
  autoload :Configuration, 'hipaa-crypt/configuration'
  autoload :Encryptor, 'hipaa-crypt/encryptor'
  autoload :AttrEncryptedEncryptor, 'hipaa-crypt/attr_encrypted_encryptor'
  autoload :Attributes, 'hipaa-crypt/attributes'
  autoload :EncryptedObject, 'hipaa-crypt/encrypted_object'
  autoload :Error, 'hipaa-crypt/error'
  autoload :MultiEncryptor, 'hipaa-crypt/multi_encryptor'

  def self.root
    File.dirname __FILE__
  end

  # Returns the Hipaa-Crypt Configuration
  # @param [Proc] block
  # @return [HipaaCrypt::Configuration]
  def self.config(&block)
    (@config ||= default_config).tap { |config| block.call config if block_given? }
  end

  def self.default_config
    Configuration.new.tap do |config|
      # Other Options
      config[:silent_re_encrypt] = false

      # The global defaults
      config[:cipher]            = { name: :AES, key_length: 256, mode: :CBC }
      config[:logger]            = (defined?(Rails) ? Rails.logger : Logger.new(STDOUT))
      config[:encryptor]         ||= HipaaCrypt::Encryptor
      config[:prefix]            ||= 'encrypted_'
      config[:suffix]            ||= nil
    end
  end

end