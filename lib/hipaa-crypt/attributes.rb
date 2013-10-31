module HipaaCrypt
  module Attributes

    autoload :ActiveRecord, 'hipaa-crypt/attributes/active_record'

    def self.included(base)
      base.extend(ClassMethods)
      base.send :include, ActiveRecord if defined?(::ActiveRecord::Base) && base.ancestors.include?(::ActiveRecord::Base)
    end

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
          @encrypted_attributes.merge(superclass.send __method__) :
          @encrypted_attributes
      end

      def set_encrypted_attribute(attr, encryptor)
        @encrypted_attributes       ||= {}
        @encrypted_attributes[attr] = encryptor
      end

      private

      def define_encrypted_attr(attr, options)
        encryptor = options.delete(:encryptor) { Encryptor }
        prefix    = options[:prefix] ||= :encrypted_
        set_encrypted_attribute attr, encryptor.new(options)

        define_unencrypted_methods_for_attr attr
        prefix_unencrypted_methods_for_attr prefix, attr

        if options[:iv].is_a?(Symbol) && setter_defined?(options[:iv])
          define_encrypted_methods_for_attr_with_settable_iv attr, prefix, options[:iv]
        elsif options.has_key? :iv
          define_encrypted_methods_for_attr_with_iv attr, prefix
        else
          define_encrypted_methods_for_attr attr, prefix
        end

        attr
      end

      def define_encrypted_methods_for_attr(attr, prefix)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{attr}
            encrypted_attributes[:#{attr}] ||= begin
              enc_val = #{prefix}#{attr}
              return nil if enc_val.nil?
              encryptor_for(#{attr.inspect}).decrypt *enc_val.to_s.split("\n", 2).reverse
            end
          end

          def #{attr}=(value)
            self.#{prefix}#{attr} = [encryptor_for(#{attr.inspect}).encrypt(value)].flatten.reverse.join("\n")
            encrypted_attributes.delete(:#{attr})
            value
          end
        RUBY
      end

      def define_encrypted_methods_for_attr_with_iv(attr, prefix)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{attr}
            encrypted_attributes[:#{attr}] ||= begin
              enc_val = #{prefix}#{attr}
              return nil if enc_val.nil?
              encryptor_for(#{attr.inspect}).decrypt enc_val
            end
          end

          def #{attr}=(value)
            string, iv = encryptor_for(#{attr.inspect}).encrypt(value)
            self.#{prefix}#{attr} = string
            encrypted_attributes.delete(:#{attr})
            value
          end
        RUBY
      end

      def define_encrypted_methods_for_attr_with_settable_iv(attr, prefix, iv_method)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{attr}
            encrypted_attributes[:#{attr}] ||= begin
              enc_val = #{prefix}#{attr}
              return nil if enc_val.nil?
              encryptor_for(#{attr.inspect}).decrypt enc_val
            end
          end

          def #{attr}=(value)
            string, iv = encryptor_for(#{attr.inspect}).encrypt(value)
            self.#{setter_for(iv_method)} iv
            self.#{prefix}#{attr} = string
            encrypted_attributes.delete(:#{attr})
            value
          end
        RUBY
      end

      def define_unencrypted_methods_for_attr(attr)
        attr_reader attr unless method_defined?("#{attr}")
        attr_writer attr unless method_defined?("#{attr}=")
      end

      def prefix_unencrypted_methods_for_attr(prefix, attr)
        alias_method "#{prefix}#{attr}", "#{attr}" unless method_defined? "#{prefix}#{attr}"
        alias_method "#{prefix}#{attr}=", "#{attr}=" unless method_defined? "#{prefix}#{attr}="
      end

      def setter_defined?(method)
        method_defined?("#{method}=".to_sym)
      end

      def setter_for(method)
        "#{method}=".to_sym
      end

    end

    # Instance Methods

    private

    def encryptor_for(attr)
      encryptors[attr] ||= self.class.encryptor_for(attr).with_context(self)
    end

    def encryptors
      @encryptors ||= {}
    end

    def encrypted_attributes
      @encrypted_attributes ||= {}
    end

  end
end