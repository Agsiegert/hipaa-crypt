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
          alias_method :active_record_attributes, :attributes
          alias_method :attributes, :attributes_without_encrypted_values
        end

        # Extends the base encryption logger.
        # @see HipaaCrypt::Attributes#encryption_logger
        def encryption_logger
          @encryption_logger ||= HipaaCrypt.config.logger.tap do |logger|
            logger.formatter = LogFormatter.new(self) if logger.respond_to? :formatter=
          end
        end

        def attributes_with_decrypted_values
          self.class.encrypted_attributes.keys.reduce(active_record_attributes) do |hash, attr|
            hash.merge attr => read_attribute(attr)
          end
        end

        # Returns an attributes hash with decrypted value.
        # @return [Hash]
        def attributes_without_encrypted_values
          keys = self.class.encrypted_attributes.keys.map { |attr| conductor_for(attr).encrypted_attribute }
          attributes_with_decrypted_values.except *(keys.map(&:to_s) + keys.map(&:to_sym))
        end

        # Returns an attributes hash with only encrypted attributes and their values.
        # @return [Hash]
        def encrypted_attributes
          keys = self.class.encrypted_attributes.keys.map { |attr| conductor_for(attr).encrypted_attribute }
          attributes_with_decrypted_values.slice *(keys.map(&:to_s) + keys.map(&:to_sym))
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