require 'active_support/core_ext/array/extract_options'

module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord
        module ClassMethods

          private

          def define_encrypted_attr(attr, options)
            define_method("#{attr}?"){ !!__enc_get__(attr) }
            super
          end

          def alias_unencrypted_methods_for_attr(attr)
            enc = encryptor_for(attr)
            super unless enc && column_names.include?(enc.options[:attribute].to_s)
          end

          def define_unencrypted_methods_for_attr(attr)
            super unless column_names.include? attr.to_s
          end

          def setter_defined?(attr)
            column_names.include? attr.to_s
          end

          if ::ActiveRecord::VERSION::STRING < '4.0.0'

            def all_attributes_exists?(attribute_names)
              attr_names_with_enc = attribute_names.map do |attr|
                if attribute_encrypted?(attr)
                  encryptor = encryptor_for attr
                  encryptor.options[:attribute]
                else
                  attr
                end
              end
              super(attr_names_with_enc)
            end

          end

        end
      end
    end
  end
end
