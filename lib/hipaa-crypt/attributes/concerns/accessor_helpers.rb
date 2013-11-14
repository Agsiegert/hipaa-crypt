module HipaaCrypt
  module Attributes
    module AccessorHelpers

      def __enc_get__(attr)
        public_send("_decrypt_#{attr}")
      end

      def __enc_fetch__(attr)
        cloned_instance = self.clone
        cloned_instance.extend Module.new { def encryption_logger() @encryption_logger ||= Logger.new('/dev/null') end }
        cloned_instance.__enc_get__ attr
      rescue Error
        nil
      end

      def __enc_set__(attr, value)
        public_send("_encrypt_#{attr}", value)
      end

      private

      def read_encrypted_attr(attr)
        public_send "#{encrypted_attribute_for(attr)}"
      end

      def write_encrypted_attr(attr, value)
        public_send "#{encrypted_attribute_for(attr)}=", value
      end

      def read_iv(attr)
        public_send iv_attribute_for(attr)
      end

      def write_iv(attr, value)
        public_send "#{iv_attribute_for(attr)}=", value
      end

      def encrypted_attribute_for(attr)
        encryptor_for(attr).options[:attribute]
      end

      def iv_attribute_for(attr)
        encryptor_for(attr).options[:iv]
      end

    end
  end
end