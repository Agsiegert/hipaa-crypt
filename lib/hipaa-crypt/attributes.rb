module HipaaCrypt
  module Attributes

    autoload :Adapters, 'hipaa-crypt/attributes/adapters'
    autoload :Memoization, 'hipaa-crypt/attributes/concerns/memoization'
    autoload :AccessorHelpers, 'hipaa-crypt/attributes/concerns/accessor_helpers'
    autoload :ReEncryption, 'hipaa-crypt/attributes/concerns/re_encryption'
    autoload :ClassMethods, 'hipaa-crypt/attributes/class_methods'

    include Memoization
    include AccessorHelpers
    include ReEncryption

    def self.included(base)
      base.extend(ClassMethods)
      base.send :include, Adapters::ActiveRecord if defined?(::ActiveRecord::Base) && base <= ::ActiveRecord::Base
    end

    # Instance Methods

    def initialize_clone(other_object)
      @encryptors           = nil
      @encrypted_attributes = nil
      super
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

  end
end