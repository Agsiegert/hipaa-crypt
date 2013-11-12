require 'active_support/rescuable'
require 'active_support/concern'

module HipaaCrypt
  module Attributes

    autoload :Adapters, 'hipaa-crypt/attributes/adapters'
    autoload :Memoization, 'hipaa-crypt/attributes/concerns/memoization'
    autoload :AccessorHelpers, 'hipaa-crypt/attributes/concerns/accessor_helpers'
    autoload :ReEncryption, 'hipaa-crypt/attributes/concerns/re_encryption'
    autoload :ClassMethods, 'hipaa-crypt/attributes/class_methods'

    include AccessorHelpers
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

    def attribute_encrypted?(attr)
      any_class __method__, attr
    end

    def encryptor_for(attr)
      encryptors[attr] ||= any_class(:encryptor_for, attr).with_context(self)
    end

    def any_class(*args)
      self.singleton_class.send(*args) || self.class.send(*args)
    end

    def encryptors
      @encryptors ||= {}
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