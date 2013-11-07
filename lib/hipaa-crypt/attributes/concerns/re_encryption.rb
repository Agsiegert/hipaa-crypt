require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/array/extract_options'

module HipaaCrypt
  module Attributes
    module ReEncryption

      def re_encrypt(*attrs)
        re_encrypt!(*attrs)
      rescue OpenSSL::Cipher::CipherError
        false
      end

      def re_encrypt!(*attrs)
        options         = attrs.extract_options!
        cloned_instance = self.clone
        attrs.each do |attr|

          # Duplicate the instance and give it the old encryptor
          current_encryptor_for_attr = encryptor_for(attr)
          options[:encryptor]        ||= current_encryptor_for_attr.class
          old_encryptor_options      = current_encryptor_for_attr.options.options.deep_merge options
          cloned_instance.singleton_class.encrypt(attr, old_encryptor_options)

          # Decrypt the duplicated instance using the getter and
          # re-encrypt the original instance using the setter
          unless decryptable?(attr) && __get__(attr) == cloned_instance.__get__(attr)
            __set__ attr, cloned_instance.__get__(attr)
            # Confirm we can read the new value
            __get__ attr
          end
        end
        true
      end

      private

      def decryptable?(attr)
        __get__ attr
      rescue Error
        false
      end

    end
  end
end