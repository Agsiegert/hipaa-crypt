module HipaaCrypt
  module Attributes
    module ReEncryption

      def re_encrypt(*attrs)
        re_encrypt!(*attrs)
      rescue
        false
      end

      def re_encrypt!(*attrs)
        options         = attrs.last.is_a?(Hash) ? attrs.pop : {}
        cloned_instance = self.clone
        attrs.each do |attr|

          # Duplicate the instance and give it the old encryptor
          current_encryptor_for_attr = encryptor_for(attr)
          options[:encryptor]        ||= current_encryptor_for_attr.class
          old_encryptor_options      = deep_merge_options(current_encryptor_for_attr.options.options, options)
          cloned_instance.singleton_class.encrypt(attr, old_encryptor_options)

          # Decrypt the duplicated instance using the getter and
          # re-encrypt the original instance using the setter
          __set__ attr, cloned_instance.__get__(attr)

          # Confirm we can read the new value
          read_encrypted_attr(attr)
        end
        true
      end

      private

      def deep_merge_options(current_options, options_to_merge)
        merger = ->(key, v1, v2) { Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        current_options.merge(options_to_merge, &merger)
      end

    end
  end
end