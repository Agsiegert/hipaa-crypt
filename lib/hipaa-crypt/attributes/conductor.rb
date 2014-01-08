module HipaaCrypt
  module Attributes
    class Conductor

      attr_reader :original_attribute, :options, :instance, :encrypted_attribute, :encryptor

      def initialize(instance, options)
        @options             = options
        @encryptor           = options[:encryptor]
        @encrypted_attribute = options[:attribute]
        @original_attribute  = options[:original_attribute]
        @instance            = instance
      end

      def joined_iv?
        !options.has_key? :iv
      end

      def encryptor_from_options(options = {})
        @encryptor.new convert_options.merge options
      end

      def encrypt(value)
        return encrypt_with_joined_iv(value) if joined_iv?
        encryptor = encryptor_from_options
        write_iv encryptor.iv if options[:iv].is_a?(Symbol)
        write encryptor.encrypt value
      end

      def encrypt_with_joined_iv(value)
        iv              = SecureRandom.base64(44)
        encryptor       = encryptor_from_options iv: iv
        encrypted_value = encryptor.encrypt(value)
        write [iv, encrypted_value].join("\n")
      end

      def decryptable?
        return decryptable_with_joined_iv? if joined_iv?
        encrypted_value = read
        return true if encrypted_value.blank?
        encryptor_from_options.decryptable? encrypted_value
      end

      def decrypt
        return decrypt_with_joined_iv if joined_iv?
        encrypted_value = read
        return encrypted_value if encrypted_value.blank?
        encryptor_from_options.decrypt encrypted_value
      end

      def read
        instance.send encrypted_attribute
      end

      private

      def decryptable_with_joined_iv?
        encrypted_value = read
        return true if encrypted_value.blank?
        iv, value = encrypted_value.split("\n", 2)
        encryptor = encryptor_from_options iv: iv
        encryptor.decryptable?(value)
      end

      def decrypt_with_joined_iv
        encrypted_value = read
        return encrypted_value if encrypted_value.blank?
        iv, value = encrypted_value.split("\n", 2)
        encryptor = encryptor_from_options iv: iv
        encryptor.decrypt(value)
      end

      def write(value)
        instance.send "#{encrypted_attribute}=", value
      end

      def write_iv(value)
        instance.send "#{options[:iv]}=", value
      end

      def convert_options(object = self.options)
        case object
        when Hash
          convert_options_hash object
        when Array
          convert_options_array object
        when Symbol
          convert_options_symbol object
        when Proc
          convert_options_proc object
        else
          convert_options_value object
        end
      end

      def convert_options_hash(hash)
        hash.reduce({}) do |h, (key, value)|
          h.merge! key => convert_options(value)
        end
      end

      def convert_options_array(array)
        array.map { |item| convert_options item }
      end

      def convert_options_symbol(symbol)
        instance.respond_to?(symbol) ? instance.send(symbol) : convert_options_value(symbol)
      end

      def convert_options_proc(proc)
        if proc.arity == 0
          instance.instance_eval(&proc)
        else
          proc.call instance
        end
      end

      def convert_options_value(value)
        value
      end


    end
  end
end