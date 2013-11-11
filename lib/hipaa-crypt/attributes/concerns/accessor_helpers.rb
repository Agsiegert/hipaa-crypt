module HipaaCrypt
  module Attributes
    module AccessorHelpers

      def __get__(attr)
        public_send(attr)
      end

      def __fetch__(attr)
        cloned_instance = self.clone
        cloned_instance.extend Module.new { def encryption_logger() @encryption_logger ||= Logger.new('/dev/null') end }
        cloned_instance.__get__ attr
      rescue Error
        nil
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