require 'active_record'
require 'active_support/concern'

module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord

        autoload :RelationAdditions, 'hipaa-crypt/attributes/adapters/active_record/relation_additions'
        autoload :ClassMethods, 'hipaa-crypt/attributes/adapters/active_record/class_methods'

        extend ActiveSupport::Concern

        def matches_conditions(conditions={})
          conditions.reduce(true) do |result, (attr, value)|
            result && matches_condition(attr, value)
          end
        end

        def matches_condition(attr, value)
          instance_eval(&attr.to_sym) == value
        end

        def encryption_logger
          @encryption_logger ||= HipaaCrypt.config.logger.tap do |logger|
            logger.formatter = LogFormatter.new(self)
          end
        end

        def attributes
          super.tap do |hash|
            self.class.encrypted_attributes.each do |attr, encryptor|
              hash.delete encryptor.options[:attribute].to_s
              hash.delete encryptor.options[:attribute].to_sym
              hash[attr.to_s] = __get__ attr
            end
          end
        end

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