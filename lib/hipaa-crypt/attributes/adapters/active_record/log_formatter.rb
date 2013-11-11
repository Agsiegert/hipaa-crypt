module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord
        class LogFormatter
          attr_reader :record

          def initialize(record)
            @record = record
          end

          def call(severity, time, progname, msg)
            "#{severity.upcase} [#{time}] #<#{record.class.name} id: #{record.id}> #{msg}\n"
          end

        end
      end
    end
  end
end
