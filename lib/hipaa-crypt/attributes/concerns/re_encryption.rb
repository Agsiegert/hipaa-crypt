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
        cloned_instance = self.clone
        attrs.each do |attr|

          # Duplicate the instance and give it the old encryptor
          conductor = conductor_for(attr)
          current_encryptor_for_attr = conductor.encryptor_from_options(options)
          options[:encryptor]        ||= current_encryptor_for_attr.class
          old_encryptor_options      = current_encryptor_for_attr.options.deep_merge(options)
          cloned_instance.singleton_class.encrypt(attr, old_encryptor_options)
          # Decrypt the duplicated instance using the getter and
          # re-encrypt the original instance using the setter
          unless decryptable?(attr) && (!cloned_instance.decryptable?(attr) || __enc_fetch__(attr) == cloned_instance.__enc_fetch__(attr))
          # unless conductor_for(attr).decryptable? && (!cloned_instance.conductor_for(attr).decryptable? || conductor_for(attr).decrypt == cloned_instance.conductor_for(attr).decrypt)
            __enc_set__ attr, cloned_instance.send(:__enc_get__, attr)
            # Confirm we can read the new value
            __enc_get__ attr
          end
        end
        true
      end

      # Determines whether or not an attribute is decryptable
      # @param [String/Symbol] attr
      # @return boolean
      def decryptable?(attr)
        !!__enc_fetch__(attr)
      end

    end
  end
end