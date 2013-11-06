module HipaaCrypt
  module Attributes
    module ClassMethods

      def attribute_encrypted?(attr)
        !!encrypted_attributes[attr.to_sym]
      end

      def encrypt(*attrs)
        options = attrs.last.is_a?(Hash) ? attrs.pop : {}
        attrs.each { |attr| define_encrypted_attr attr, options }
      end

      def encryptor_for(attr)
        encrypted_attributes[attr.to_sym]
      end

      def encrypted_attributes
        @encrypted_attributes ||= {}
        superclass.respond_to?(__method__) ?
          superclass.send(__method__).merge(@encrypted_attributes) : @encrypted_attributes
      end

      def set_encrypted_attribute(attr, encryptor)
        @encrypted_attributes       ||= {}
        @encrypted_attributes[attr] = encryptor
      end

      private

      def define_encrypted_attr(attr, options)
        options                       = options.dup
        encryptor_klass               = options.delete(:encryptor) { Encryptor }
        options[:attribute]           = attr
        options[:prefix]              ||= :encrypted_
        options[:suffix]              ||= nil
        options[:encrypted_attribute] ||= options.values_at(:prefix, :attribute, :suffix).compact.join

        set_encrypted_attribute attr, encryptor_klass.new(options)

        define_unencrypted_methods_for_attr attr
        alias_unencrypted_methods_for_attr attr

        if options[:iv].is_a?(Symbol) && setter_defined?(options[:iv])
          define_encrypted_methods_for_attr_with_settable_iv attr
        elsif options.has_key? :iv
          define_encrypted_methods_for_attr_with_iv attr
        else
          define_encrypted_methods_for_attr attr
        end

        attr
      end

      def define_encrypted_methods_for_attr(attr)
        define_encrypted_attr_getter(attr) do
          __memoize__(attr) do
            enc_val = read_encrypted_attr(attr)
            return enc_val if enc_val.nil? || enc_val.empty?
            iv, value = enc_val.split("\n", 2)
            encryptor_for(attr).decrypt value, iv
          end
        end

        define_encrypted_attr_setter(attr) do |value|
          value, iv = value.nil? ? nil : encryptor_for(attr).encrypt(value)
          write_encrypted_attr attr, value ? [iv, value].join("\n") : nil
          value
        end
      end

      def define_encrypted_methods_for_attr_with_iv(attr)
        define_encrypted_attr_getter(attr) do
          __memoize__(attr) do
            enc_val = read_encrypted_attr(attr)
            return enc_val if enc_val.nil? || enc_val.empty?
            encryptor_for(attr).decrypt enc_val
          end
        end

        define_encrypted_attr_setter(attr) do |value|
          string, iv = value.nil? ? [nil, nil] : encryptor_for(attr).encrypt(value)
          write_encrypted_attr attr, string
          value
        end
      end

      def define_encrypted_methods_for_attr_with_settable_iv(attr)
        define_encrypted_attr_getter(attr) do
          __memoize__(attr) do
            enc_val = read_encrypted_attr(attr)
            return enc_val if enc_val.nil? || enc_val.empty?
            encryptor_for(attr).decrypt enc_val, read_iv(attr)
          end
        end

        define_encrypted_attr_setter(attr) do |value|
          string, iv = value.nil? ? [nil, nil] : encryptor_for(attr).encrypt(value)
          write_iv attr, iv
          write_encrypted_attr attr, string
          value
        end
      end

      def define_encrypted_attr_getter(attr, &block)
        define_method "#{attr}", &block
      end

      def define_encrypted_attr_setter(attr, &block)
        define_method "#{attr}=", &block
      end

      def define_unencrypted_methods_for_attr(attr)
        attr_reader attr unless method_defined?("#{attr}")
        attr_writer attr unless method_defined?("#{attr}=")
      end

      def alias_unencrypted_methods_for_attr(attr)
        if (enc = encryptor_for(attr))
          enc_attr = enc.options[:encrypted_attribute]
          alias_method "#{enc_attr}", "#{attr}" unless method_defined? "#{enc_attr}"
          alias_method "#{enc_attr}=", "#{attr}=" unless method_defined? "#{enc_attr}="
        end
      end

      def setter_defined?(method)
        method_defined?("#{method}=".to_sym)
      end

    end
  end
end