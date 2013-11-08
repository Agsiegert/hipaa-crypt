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

        def encryption_logger
          @encryption_logger ||= HipaaCrypt.config.logger.tap do |logger|
            logger.formatter = LogFormatter.new(self)
          end
        end

        def attributes
          super.tap do |hash|
            self.class.encrypted_attributes.each do |attr, encryptor|
              hash.delete encryptor.options[:attribute].to_s
              hash.delete encryptor.options[:attribute].to_sym
              hash[attr.to_s] = __get__ attr
            end
          end
        end

        def __set__(attr, value)
          send "#{attr}_will_change!" if respond_to?("#{attr}_will_change!") && value != __get__(attr)
          super
        end

      end
    end
  end
end