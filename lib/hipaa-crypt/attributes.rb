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
        define_encrypted_methods_for_attr attr, prefix

        attr
      end

      def define_encrypted_methods_for_attr(attr, prefix)
        alias_method "#{prefix}#{attr}", "#{attr}"
        alias_method "#{prefix}#{attr}=", "#{attr}="

        define_method("#{attr}") do
          args = send("#{prefix}#{attr}").to_s.split("\n", 2).reverse
          encryptor_for(attr).decrypt *args
        end

        define_method("#{attr}=") do |value|
          string = [encryptor_for(attr).encrypt(value)].flatten.reverse.join("\n")
          send "#{prefix}#{attr}=", string
        end
      end

      def define_unencrypted_methods_for_attr(attr)
        attr_reader attr unless method_defined?("#{attr}")
        attr_writer attr unless method_defined?("#{attr}=")
      end

    end

  end
end