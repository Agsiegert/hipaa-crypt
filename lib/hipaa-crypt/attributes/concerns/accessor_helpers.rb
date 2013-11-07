module HipaaCrypt
  module Attributes
    module AccessorHelpers

      def __get__(attr)
        public_send(attr)
      rescue Exception => exception
        rescue_with_handler(exception) || raise(exception)
      end

      def __set__(attr, value)
        public_send("#{attr}=", value)
      rescue Exception => exception
        rescue_with_handler(exception) || raise(exception)
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
        __get__ iv_attribute_for(attr)
      end

      def write_iv(attr, value)
        __set__ iv_attribute_for(attr), value
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