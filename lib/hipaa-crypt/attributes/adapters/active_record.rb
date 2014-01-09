require 'active_record'
require 'active_support/concern'

module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord

        autoload :RelationAdditions, 'hipaa-crypt/attributes/adapters/active_record/relation_additions'
        autoload :ClassMethods, 'hipaa-crypt/attributes/adapters/active_record/class_methods'
        autoload :LogFormatter, 'hipaa-crypt/attributes/adapters/active_record/log_formatter'
        autoload :Matchers, 'hipaa-crypt/attributes/adapters/active_record/matchers'
        autoload :CallbackSkipper, 'hipaa-crypt/attributes/adapters/active_record/callback_skipper'
        autoload :ReEncryptionClassMethods, 'hipaa-crypt/attributes/adapters/active_record/re_encryption'

        extend ActiveSupport::Concern
        include Matchers

        included do
          extend ReEncryptionClassMethods
        end

        # Extends the base encryption logger.
        # @see HipaaCrypt::Attributes#encryption_logger
        def encryption_logger
          @encryption_logger ||= HipaaCrypt.config.logger.tap do |logger|
            logger.formatter = LogFormatter.new(self) if logger.respond_to? :formatter=
          end
        end

        # Returns an attributes hash with decrypted value.
        # @return [Hash]
        def attributes
          super.tap do |hash|
            self.class.encrypted_attributes.each do |attr, encryptor|
              hash.delete encryptor[:attribute].to_s
              hash.delete encryptor[:attribute].to_sym
              hash[attr.to_s] = read_attribute(attr)
            end
          end
        end

        # Extends ActiveRecord's #write_attribute to support encrypted attrs.
        # @param [Symbol/String] attr
        # @param value
        def write_attribute(attr, value)
          if attribute_encrypted?(attr)
            conductor_for(attr).encrypt(value)
          else
            super(attr, value)
          end
        end

        # Extends ActiveRecord's #read_attribute to support encrypted attrs.
        # @param [Symbol/String] attr
        def read_attribute(attr)
          if attribute_encrypted?(attr)
            conductor_for(attr).decrypt
          else
            super(attr)
          end
        end

      end
    end
  end
end