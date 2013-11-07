require 'bundler/setup'

module HipaaCrypt

  autoload :Callbacks, 'hipaa-crypt/callbacks'
  autoload :Configuration, 'hipaa-crypt/configuration'
  autoload :Encryptor, 'hipaa-crypt/encryptor'
  autoload :AttrEncryptedEncryptor, 'hipaa-crypt/attr_encrypted_encryptor'
  autoload :Attributes, 'hipaa-crypt/attributes'
  autoload :EncryptedObject, 'hipaa-crypt/encrypted_object'
  autoload :Error, 'hipaa-crypt/error'

  def self.config(&block)
    (@config ||= Configuration.new).tap do |config|
      block.call(config) if block_given?
    end
  end

end