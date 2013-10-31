module HipaaCrypt
  module Attributes

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def encrypt(*attrs)
        options = attrs.last.is_a?(Hash) ? attrs.pop : {}
        attrs.each { |attr| define_encrypted_attr attr, options }
      end

      def set_encrypted_attribute(attr, encryptor)
        @encrypted_attributes ||= {}
        @encrypted_attributes[attr] = encryptor
      end

      def encrypted_attributes
        @encrypted_attributes ||= {}
        superclass.respond_to?(__method__) ?
          superclass.send(__method__).merge(@encrypted_attributes) : @encrypted_attributes
      end

      private

      def define_encrypted_attr(attr, options)
        encryptor = options.delete(:encryptor) { Encryptor }
        prefix = options.delete(:prefix) { 'encrypted_' }
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
            encryptor_for(#{attr.inspect}).decrypt *#{prefix}#{attr}.to_s.split("\n", 2).reverse
          end

          def #{attr}=(value)
            self.#{prefix}#{attr} = [encryptor_for(#{attr.inspect}).encrypt(value)].flatten.reverse.join("\n")
          end
        RUBY
      end

      def define_encrypted_methods_for_attr_with_iv(attr, prefix)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{attr}
            string = #{prefix}#{attr}
            encryptor_for(#{attr.inspect}).decrypt string
          end

          def #{attr}=(value)
            string, iv = encryptor_for(#{attr.inspect}).encrypt(value)
            self.#{prefix}#{attr}= string
          end
        RUBY
      end

      def define_encrypted_methods_for_attr_with_settable_iv(attr, prefix, iv_method)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{attr}
            string = #{prefix}#{attr}
            encryptor_for(#{attr.inspect}).decrypt string
          end

          def #{attr}=(value)
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

    def re_encrypt(*attrs)
      options = attrs.last.is_a?(Hash) ? attrs.pop : {}
      attrs.each do |attr|
        # Duplicate the instance and give it the old encryptor
        current_encryptor_for_attr = encryptor_for(attr)
        options[:encryptor] ||= current_encryptor_for_attr.class
        options[:prefix] ||= 'encrypted_'
        old_encryptor_options = deep_merge_options(current_encryptor_for_attr.options.options, options)
        duped_instance = self.dup
        duped_instance.instance_variable_set(:@encryptors, nil)
        duped_instance.singleton_class.instance_variable_set(:@encrypted_attributes, nil)
        duped_instance.singleton_class.encrypt(attr, old_encryptor_options)

        # Decrypt the duplicated instance using the getter and
        # re-encrypt the original instance using the setter
        send "#{attr}=", duped_instance.send(attr)
      end
    end

    private

    def encryptor_for(attr)
      encryptors[attr] ||= (self.singleton_class.encrypted_attributes[attr] ||
          self.class.encrypted_attributes[attr]).
          with_context(self)
    end

    def encryptors
      @encryptors ||= {}
    end

    def deep_merge_options(current_options, options_to_merge)
      merger = ->(key, v1, v2) { Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
      current_options.merge(options_to_merge, &merger)
    end

  end
end