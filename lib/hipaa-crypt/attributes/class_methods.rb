require 'active_support/core_ext/array/extract_options'

module HipaaCrypt
  module Attributes
    module ClassMethods

      # Returns if an attribute is encrypted.
      # @param [String/Symbol] attr
      # @return [Boolean]
      def attribute_encrypted?(attr)
        encrypted_options_for(attr.to_sym)
      rescue ArgumentError
        false
      else
        true
      end

      # Mark attributes for encryption with the given options.
      #
      # @!method encrypt(*attrs, options={})
      # @param [Strings/Symbols] attrs - attributes to re-encrypt.
      # @param [Hash] options - options for the source of the re-encryption.
      # @option options [String] :key - The encryption key.
      # @option options [Hash/String] :cipher - The encryption cipher. defaults to 'aes-256-cbc'
      # @option options [String/Symbol] :iv - The encryption iv.
      # @option options [HipaaCrypt::Encryptor] :encryptor - The encryptor. defaults to HipaaCrypt::Encryptor
      #
      # @example Encrypt :foo and :bar
      #   class MyClass
      #     include HipaaCrypt::Attributes
      #
      #     encrypt :foo, :bar, key: 'my-secret-key'
      #
      #   end
      def encrypt(*attrs)
        options = attrs.extract_options!
        attrs.each { |attr| define_encrypted_attr attr, options }
      end

      # Return the encryptor for the given attribute
      # @param [String/Symbol] attr - the encrypted attribute
      # @return [HipaaCrypt::Encryptor]
      def encrypted_options_for(attr)
        raise ArgumentError, "#{attr} is not encrypted" unless encrypted_attributes.has_key? attr.to_sym
        encrypted_attributes[attr]
      end

      # All the encrypted attributes, with the keys as the attrs and the encryptors as values.
      # @return [Hash]
      def encrypted_attributes
        @encrypted_attributes ||= HashWithIndifferentAccess.new
        superclass.respond_to?(__method__) ?
            superclass.send(__method__).merge(@encrypted_attributes) : @encrypted_attributes
      end

      private

      def set_encrypted_attribute(attr, options)
        @encrypted_attributes ||= HashWithIndifferentAccess.new
        @encrypted_attributes[attr] = options
      end

      def define_encrypted_attr(attr, options)
        options = options.reverse_merge(HipaaCrypt.config).with_indifferent_access
        options[:original_attribute] ||= attr.to_s
        options[:attribute] ||= options.values_at(:prefix, :original_attribute, :suffix).compact.join

        set_encrypted_attribute attr, options
        alias_unencrypted_methods_for_attr attr
        define_encrypted_methods_for_attr attr

        attr
      end

      def define_encrypted_methods_for_attr(attr)
        define_encrypted_attr_getter(attr) do
          with_rescue do
            conductor_for(attr).decrypt
          end
        end

        define_encrypted_attr_setter(attr) do |value|
          with_rescue do
            if respond_to?(:attribute_will_change!, true) && respond_to?(:read_attribute) && value != read_attribute(attr)
              attribute_will_change! attr
            end
            conductor_for(attr).encrypt(value)
          end
        end
      end

      def define_encrypted_attr_getter(attr, &block)
        define_method "_decrypt_#{attr}", &block
        __memoize_method__("_decrypt_#{attr}")
        alias_method attr, "_decrypt_#{attr}"
      end

      def define_encrypted_attr_setter(attr, &block)
        define_method "_encrypt_#{attr}", &block
        __clear_memoize_method__ "_decrypt_#{attr}", with: "_encrypt_#{attr}"
        alias_method "#{attr}=", "_encrypt_#{attr}"
      end

      def alias_unencrypted_methods_for_attr(attr)
        if (options = encrypted_options_for(attr))
          enc_attr = options[:attribute]
          alias_method "#{enc_attr}", "#{attr}" if method_externally_defined?("#{attr}")
          alias_method "#{enc_attr}=", "#{attr}=" if method_externally_defined?("#{attr}=")
        end
      end

      def method_externally_defined?(m)
        method_defined?(m) && begin
          filename, line_number = instance_method(m).source_location
          !filename.include?(HipaaCrypt.root)
        end

      end

      def method_added(method)
        if attribute_encrypted?(method) && !caller.any? { |method| method.include? 'method_added' }
          options = encrypted_options_for(method)
          encrypt(method, options)
        end
        super
      end

      def setter_defined?(method)
        method_defined?("#{method}=".to_sym)
      end

    end
  end
end