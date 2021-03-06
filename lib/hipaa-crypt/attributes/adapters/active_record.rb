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
        autoload :ReEncryptor, 'hipaa-crypt/attributes/adapters/active_record/re_encryptor'

        extend ActiveSupport::Concern
        include Matchers

        included do
          extend ReEncryption
          extend RelationAdditions::Extender
          alias_method :active_record_attributes, :attributes
          alias_method :attributes, :attributes_without_encrypted_values
        end

        module ReEncryption

          # Re-encrypt, logging an error and continuing when an error occurs.
          #
          # *NOTE:* options should always be the *_old_* options for encryption.
          #    - example: instance.re_encrypt(:foo, :bar, key: ENV['OLD_KEY'])
          #
          # @!method re_encrypt(*attributes, options={})
          # @!scope class
          # @param attributes
          # @param [Hash] options
          # @option options [String] :key - The old encryption key.
          # @option options [Hash/String] :cipher - The old encryption cipher.
          # @option options [String/Symbol] :iv - The old encryption iv.
          # @option options [HipaaCrypt::Encryptor] :encryptor - The old encryptor.

          # Re-encrypt and raise error when a failure occurs.
          #
          # *NOTE:* options should always be the *_old_* options for encryption.
          #    - example: instance.re_encrypt(:foo, :bar, key: ENV['OLD_KEY'])
          #
          # @!method re_encrypt!(*attributes, options={})
          # @!scope class
          # @param attributes
          # @param [Hash] options
          # @option options [String] :key - The old encryption key.
          # @option options [Hash/String] :cipher - The old encryption cipher.
          # @option options [String/Symbol] :iv - The old encryption iv.
          # @option options [HipaaCrypt::Encryptor] :encryptor - The old encryptor.

          # @!method method
          # @!visibility private

          # @!method method=
          # @!visibility private


          [:re_encrypt, :re_encrypt!].each do |method|
            define_method method do |*args|
              ReEncryptor.new(self, method, *args).perform
            end
          end

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
          attributes_with_decrypted_values.except *eager_load_conductors.map(&:encrypted_attribute)
        end

        # Returns an attributes hash with only encrypted attributes and their values.
        # @return [Hash]
        def encrypted_attributes
          active_record_attributes.except(*attributes_without_encrypted_values.keys)
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