module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord
        class ReEncryptor

          attr_reader :model, :args, :options, :arel, :instance_method, :failures, :successes

          QUERY_MAP = { 'lt' => '<', 'gt' => '>' }

          def self.build_query(model, options)
            options.select { |key, value| key =~ /_(lt|gt)/ }.reduce(model.unscoped) do |rel, (key, value)|
              options.delete(key)
              operator, attr = key.to_s.reverse.split('_', 2).map(&:reverse)
              rel.where "#{attr} #{QUERY_MAP[operator]} ?", value
            end
          end

          def initialize(model, method, *args)
            @model           = model
            @args            = args.dup
            @options         = @args.extract_options!
            @arel            = self.class.build_query(model, options)
            @instance_method = method
            @failures        = []
            @successes       = []
          end

          def perform
            with_messaging do
              each_instance do |instance|
                with_printing do
                  result = instance.send(instance_method, *args.dup) && instance.save_without_callbacks
                  result ? successes << instance : failures << instance
                end
              end
              freeze
            end
            self
          end

          def each_instance(&block)
            arel.find_each do |instance|
              instance.extend CallbackSkipper
              yield instance
            end
          end

          def with_messaging(&block)
            puts_starting_message unless HipaaCrypt.config.silent_re_encrypt
            block.call.tap do
              puts_completion_message unless HipaaCrypt.config.silent_re_encrypt
            end
          end

          def with_printing(&block)
            initial_fail_count, initial_success_count = [failures, successes].map(&:count)
            block.call.tap do
              return if HipaaCrypt.config.silent_re_encrypt
              print_fail if failures.count > initial_fail_count
              print_success if successes.count > initial_success_count
            end
          end

          def puts_starting_message
            puts "\nStarting re-encryption of #{arel.count} #{model.name || model.to_s} records\n"
          end

          def print_fail
            print "\e[0;95;49mF\e[0m"
          end

          def print_success
            print "\e[0;36;49m.\e[0m"
          end

          def puts_completion_message
            puts "\nRe-Encrypted \e[0;36;49m#{successes.count}\e[0m #{model.name || model.to_s} records \e[0;95;49m#{failures.count}\e[0m failed\n"
          end

          def status
            frozen? ? :complete : :not_started
          end

          def to_s
            inspect
          end

          def inspect
            "#<#{self.class.name} status: #{status}, succeeded: #{successes.count}, failed: #{failures.count}>"
          end

        end
      end
    end
  end
end