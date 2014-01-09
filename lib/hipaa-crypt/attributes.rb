module HipaaCrypt
  module Attributes

    autoload :Adapters, 'hipaa-crypt/attributes/adapters'
    autoload :Memoization, 'hipaa-crypt/attributes/concerns/memoization'
    autoload :ReEncryption, 'hipaa-crypt/attributes/concerns/re_encryption'
    autoload :ClassMethods, 'hipaa-crypt/attributes/class_methods'
    autoload :Conductor, 'hipaa-crypt/attributes/conductor'

    include ReEncryption

    extend ActiveSupport::Concern

    included do
      include Adapters::ActiveRecord if defined?(::ActiveRecord::Base) && self <= ::ActiveRecord::Base
      include Memoization
      include ActiveSupport::Rescuable
      rescue_from HipaaCrypt::Error, with: :log_encryption_error
    end

    # Instance Methods

    def initialize_clone(other_object)
      @encryptors           = nil
      @encrypted_attributes = nil
      super
    end

    # Returns if an attribute is encrypted.
    # @param [String/Symbol] attr
    # @return [Boolean]
    def attribute_encrypted?(attr)
      any_class __method__, attr
    end

    # Return the encryptor for the given attribute
    # @param [String/Symbol] attr - the encrypted attribute
    # @return [HipaaCrypt::Encryptor]
    def encryptor_for(attr)
      conductor_for(attr).encryptor
    end

    def conductor_for(attr)
      conductors[attr] ||= begin
        options = any_class(:encrypted_options_for, attr)
        Conductor.new(self, options)
      end
    end

    def eager_load_conductors
      self.class.encrypted_attributes.keys.map do |attr|
        conductor_for(attr)
      end
    end

    private

    def any_class(*args)
      self.singleton_class.send(*args) || self.class.send(*args)
    end

    def conductors
      @conductors ||= HashWithIndifferentAccess.new
    end

    def encryption_logger
      @encryption_logger ||= HipaaCrypt.config.logger
    end

    def log_encryption_error(error)
      encryption_logger.error error
      raise error
    end

    def with_rescue(&block)
      yield
    rescue Exception => exception
      rescue_with_handler(exception) || raise(exception)
    end

  end
end