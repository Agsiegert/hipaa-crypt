module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord
        module ReEncryptionClassMethods

          # Re-encrypt, logging an error and continuing when an error occurs.
          #
          # *NOTE:* options should always be the *_old_* options for encryption.
          #    - example: instance.re_encrypt(:foo, :bar, key: ENV['OLD_KEY'])
          #
          # @!method re_encrypt(*attributes, options={})
          # @!scope class
          # @param attributes
          # @param [Hash] options
          # @option options [String] :key - The old encryption key.
          # @option options [Hash/String] :cipher - The old encryption cipher.
          # @option options [String/Symbol] :iv - The old encryption iv.
          # @option options [HipaaCrypt::Encryptor] :encryptor - The old encryptor.

          # Re-encrypt and raise error when a failure occurs.
          #
          # *NOTE:* options should always be the *_old_* options for encryption.
          #    - example: instance.re_encrypt(:foo, :bar, key: ENV['OLD_KEY'])
          #
          # @!method re_encrypt!(*attributes, options={})
          # @!scope class
          # @param attributes
          # @param [Hash] options
          # @option options [String] :key - The old encryption key.
          # @option options [Hash/String] :cipher - The old encryption cipher.
          # @option options [String/Symbol] :iv - The old encryption iv.
          # @option options [HipaaCrypt::Encryptor] :encryptor - The old encryptor.

          # @!method method
          # @!visibility private

          # @!method method=
          # @!visibility private
          [:re_encrypt, :re_encrypt!].each do |method|
            define_method method do |*args|
              args  = args.dup
              query = re_encrypt_query_from_args(args)
              query.re_encrypt_in_batches method, *args
            end
          end

          # Re-encrypt in batches.
          def re_encrypt_in_batches(method, *args)
            puts_current_model
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

          def puts_current_model
            puts "\nStarting re-encryption of #{count} #{name} records\n" unless HipaaCrypt.config.silent_re_encrypt
          end

          def print_fail
            print "\e[0;95;49mF\e[0m" unless HipaaCrypt.config.silent_re_encrypt
          end

          def print_success
            print "\e[0;36;49m.\e[0m" unless HipaaCrypt.config.silent_re_encrypt
          end

          def puts_counts(success_count, fail_count)
            puts "\nRe-Encrypted \e[0;36;49m#{success_count}\e[0m #{name} records \e[0;95;49m#{fail_count}\e[0m failed\n" unless HipaaCrypt.config.silent_re_encrypt
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
