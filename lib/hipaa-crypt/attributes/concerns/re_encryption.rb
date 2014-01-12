require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/array/extract_options'

module HipaaCrypt
  module Attributes
    module ReEncryption

      # Re-encrypt and return false when an error occurs.
      #
      # *NOTE:* options should always be the *_old_* options for encryption.
      #    - example: instance.re_encrypt(:foo, :bar, key: ENV['OLD_KEY'])
      #
      # @!method re_encrypt(*attrs, options={})
      # @param [Strings/Symbols] attrs - attributes to re-encrypt.
      # @param [Hash] options - options for the source of the re-encryption.
      # @option options [String] :key - The old encryption key.
      # @option options [Hash/String] :cipher - The old encryption cipher.
      # @option options [String/Symbol] :iv - The old encryption iv.
      # @option options [HipaaCrypt::Encryptor] :encryptor - The old encryptor.
      # @return [Boolean]

      def re_encrypt(*attrs)
        re_encrypt!(*attrs)
      rescue Error
        false
      end

      # Re-encrypt and raise error when a failure occurs.
      #
      # *NOTE:* options should always be the *_old_* options for encryption.
      #    - example: instance.re_encrypt(:foo, :bar, key: ENV['OLD_KEY'])
      #
      # @!method re_encrypt!(*attrs, options={})
      # @param [Strings/Symbols] attrs - attributes to re-encrypt.
      # @param [Hash] options - options for the source of the re-encryption.
      # @option options [String] :key - The old encryption key.
      # @option options [Hash/String] :cipher - The old encryption cipher.
      # @option options [String/Symbol] :iv - The old encryption iv.
      # @option options [HipaaCrypt::Encryptor] :encryptor - The old encryptor.
      # @return [Boolean]

      def re_encrypt!(*attrs)
        options         = attrs.extract_options!
        attrs           = self.class.encrypted_attributes.keys if attrs.blank?
        cloned_instance = self.clone
        cloned_instance.set_singleton_encryption_options(*attrs, options)
        attrs.all? do |attr|
          already_re_encrypted = decryptable?(attr) && check_cloned_instance(cloned_instance, attr)
          already_re_encrypted || !!(conductor_for(attr).encrypt cloned_instance.conductor_for(attr).decrypt)
        end
      end

      def check_cloned_instance(clone = self.clone, attr)
        clone.not_decryptable?(attr) || conductor_for(attr).decrypt == clone.conductor_for(attr).decrypt
      end

      def set_singleton_encryption_options(*attrs)
        options = attrs.extract_options!
        attrs.each do |attr|
          existing_options = self.class.encrypted_options_for(attr).except(:prefix, :original_attribute, :suffix, :attribute)
          singleton_class.encrypt attr, existing_options.deep_merge(options)
        end
        conductors.clear
      end

      # Determines whether or not an attribute is decryptable
      # @param [String/Symbol] attr
      # @return boolean
      def decryptable?(attr)
        conductor_for(attr).decryptable?
      end

      def not_decryptable?(attr)
        !decryptable?(attr)
      end

    end
  end
end