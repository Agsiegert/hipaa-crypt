module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord
        module ReEncryptionClassMethods

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
            options.select { |key, value| key =~ /_(lt|gt)/ }.reduce(unscoped) do |rel, (quop, value)|
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

        end
      end
    end
  end
end
