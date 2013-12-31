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
        write_iv encryptor.iv if options[:iv].is_a?(Symbol) && instance.respond_to?(options[:iv])
        write encryptor.encrypt value
      end

      def encrypt_with_joined_iv(value)
        iv              = SecureRandom.base64(44)
        encryptor       = encryptor_from_options iv: iv
        encrypted_value = encryptor.encrypt(value)
        write [iv, encrypted_value].join("\n")
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

      def convert_options(options = self.options)
        case options
        when Hash
          convert_options_hash options
        when Array
          convert_options_array options
        when Symbol
          convert_options_symbol options
        when Proc
          convert_options_proc options
        else
          convert_options_value options
        end
      end

      def convert_options_hash(options)
        options.reduce({}) do |hash, (key, value)|
          hash.merge! key => convert_options(value)
        end
      end

      def convert_options_array(options)
        options.map { |item| convert_options item }
      end

      def convert_options_symbol(options)
        instance.respond_to?(options) ? instance.send(options) : convert_options_value(options)
      end

      def convert_options_proc(options)
        if options.arity == 0
          instance.instance_eval(&options)
        else
          options.call instance
        end
      end

      def convert_options_value(options)
        options
      end


    end
  end
end