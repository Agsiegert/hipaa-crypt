module HipaaCrypt
  module Attributes
    module AccessorHelpers

      def __get__(attr)
        public_send(attr)
      end

      def __set__(attr, value)
        public_send("#{attr}=", value)
      end

      private

      def read_encrypted_attr(attr)
        __get__ encrypted_attribute_for(attr)
      end

      def write_encrypted_attr(attr, value)
        __clear_memo__ attr
        __set__ encrypted_attribute_for(attr), value
      end

      def read_iv(attr)
        public_send iv_attribute_for attr
      end

      def write_iv(attr, value)
        public_send("#{iv_attribute_for(attr)}=", value)
      end

      def encrypted_attribute_for(attr)
        raise ArgumentError, "#{attr} is not encrypted" unless (enc = encryptor_for(attr))
        enc.options[:attribute]
      end

      def iv_attribute_for(attr)
        encryptor_for(attr).options[:iv]
      end

    end
  end
end