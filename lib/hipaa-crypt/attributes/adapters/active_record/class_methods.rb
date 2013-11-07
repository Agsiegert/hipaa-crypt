require 'active_support/core_ext/array/extract_options'

module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord
        module ClassMethods

          module CallbackSkipper
            def save_without_callbacks
              changed_attrs = changed.reduce({}) do |hash, attr|
                hash.merge attr => read_attribute(attr)
              end
              changed_attrs.blank? || 1 == self.class.unscoped.where(self.class.primary_key => id).update_all(changed_attrs)
            rescue => e
              HipaaCrypt.logger.error "Re-Encrypt Error => #{e.class}: #{e.message}"
              false
            end
          end

          [:re_encrypt, :re_encrypt!].each do |method|
            define_method method do |*args|
              args  = args.dup
              query = re_encrypt_query_from_args(args)
              query.re_encrypt_in_batches method, *args
            end
          end

          def re_encrypt_in_batches(method, *args)
            success_count, fail_count = 0, 0
            find_each do |instance|
              instance.extend(CallbackSkipper)
              if instance.send(method, *args.dup) && instance.save_without_callbacks
                success_count += 1 and print_success
              else
                fail_count += 1 and print_fail
              end
            end

            puts_counts(success_count, fail_count)
          end

          private

          def print_fail
            print "\e[0;31;49mF\e[0m" unless HipaaCrypt.config.silent_re_encrypt
          end

          def print_success
            print "\e[0;32;49m.\e[0m" unless HipaaCrypt.config.silent_re_encrypt
          end

          def puts_counts(success_count, fail_count)
            puts "\nRe-Encrypted \e[0;32;49m#{success_count}\e[0m #{name} records \e[0;31;49m#{fail_count}\e[0m failed" unless HipaaCrypt.config.silent_re_encrypt
          end

          def re_encrypt_query_from_args(args)
            options = args.extract_options!
            ops     = { 'lt' => '<', 'gt' => '>' }
            options.select { |key, value| key =~ /_(lt|gt)/ }.reduce(relation) do |rel, (quop, value)|
              options.delete(quop)
              op, attr = quop.to_s.reverse.split('_', 2).map(&:reverse)
              rel.where "#{attr} #{ops[op]} ?", value
            end.tap { args << options }
          end

          def relation(*args)
            super(*args).tap do |relation|
              relation.extend RelationAdditions
            end
          end

          def define_encrypted_attr(attr, options)
            options.reverse_merge logger: logger
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
