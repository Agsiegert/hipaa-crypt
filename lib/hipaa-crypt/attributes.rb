module HipaaCrypt
  module Attributes

    def self.included(base)
      base.extend(ClassMethods)
    end

    private

    def encryptor_for(attr)
      encryptors[attr] ||= self.class.encrypted_attributes[attr].with_context(self)
    end

    def encryptors
      @encryptors ||= {}
    end

    module ClassMethods

      def encrypt(*attrs)
        options = attrs.last.is_a?(Hash) ? attrs.pop : {}
        attrs.each { |attr| define_encrypted_attr attr, options }
      end

      def set_encrypted_attribute(attr, encryptor)
        @encrypted_attributes       ||= {}
        @encrypted_attributes[attr] = encryptor
      end

      def encrypted_attributes
        @encrypted_attributes ||= {}
        superclass.respond_to?(__method__) ?
          @encrypted_attributes.merge(superclass.send __method__) :
          @encrypted_attributes
      end

      private

      def define_encrypted_attr(attr, options)
        encryptor = options.delete(:encryptor) { Encryptor }
        prefix    = options.delete(:prefix) { 'encrypted_' }
        set_encrypted_attribute attr, encryptor.new(options)

        define_unencrypted_methods_for_attr attr
        alias_unencrypted_methods_for_attr attr

        if options[:iv].is_a?(Symbol) && setter_defined?(options[:iv])
          define_encrypted_methods_for_attr_with_iv attr, prefix, options[:iv]
        else
          define_encrypted_methods_for_attr attr, prefix
        end

        attr
      end

      def alias_unencrypted_methods_for_attr(attr)
        alias_method "#{prefix}#{attr}", "#{attr}"
        alias_method "#{prefix}#{attr}=", "#{attr}="
      end

      def define_encrypted_methods_for_attr(attr, prefix)
        define_method("#{attr}") do
          args = send("#{prefix}#{attr}").to_s.split("\n", 2).reverse
          encryptor_for(attr).decrypt *args
        end

        define_method("#{attr}=") do |value|
          string = [encryptor_for(attr).encrypt(value)].flatten.reverse.join("\n")
          send "#{prefix}#{attr}=", string
        end
      end

      def define_encrypted_methods_for_attr_with_iv(attr, prefix, iv_method)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{attr}
            string = #{prefix}#{attr}
            iv = #{getter_for(iv_method)}
            encryptor_for(#{attr.inspect}).decrypt string, iv
          end

          def #{attr}=
            string, iv = encryptor_for(#{attr.inspect}).encrypt(value)
            self.#{setter_for(iv_method)} iv
            self.#{prefix}#{attr}= string
          end
        RUBY
      end

      def define_unencrypted_methods_for_attr(attr)
        attr_reader attr unless method_defined?("#{attr}")
        attr_writer attr unless method_defined?("#{attr}=")
      end

      def setter_defined?(method)
        method_defined?("#{method}=".to_sym)
      end

      def setter_for(method)
        "#{method}=".to_sym
      end

      def getter_for(method)
        method
      end

    end

  end
end