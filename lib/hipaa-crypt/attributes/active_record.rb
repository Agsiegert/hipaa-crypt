require 'active_record'

module HipaaCrypt
  module Attributes
    module ActiveRecord

      autoload :RelationAdditions, 'hipaa-crypt/attributes/active_record/relation_additions'
      autoload :ClassMethods, 'hipaa-crypt/attributes/active_record/class_methods'

      def self.included(base)
        base.extend(ClassMethods)
        base.after_initialize :add_log_formatter
      end

      def matches_conditions(conditions={})
        conditions.reduce(true) do |result, (attr, value)|
          result && matches_condition(attr, value)
        end
      end

      def matches_condition(attr, value)
        instance_eval(&attr.to_sym) == value
      end

      def add_log_formatter
        self.class.encrypted_attributes.each do |(attr, encryptor)|
          encryptor_for(attr).logger.formatter = LogFormatter.new(self)
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