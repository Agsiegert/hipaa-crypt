require 'active_record'

module HipaaCrypt
  module Attributes
    module ActiveRecord

      autoload :RelationAdditions, 'hipaa-crypt/attributes/active_record/relation_additions'
      autoload :ClassMethods, 'hipaa-crypt/attributes/active_record/class_methods'

      def self.included(base)
        base.extend(ClassMethods)
      end

      def matches_conditions(conditions={})
        conditions.reduce(true) do |result, (attr, value)|
          result && matches_condition(attr, value)
        end
      end

      def matches_condition(attr, value)
        instance_eval(&attr.to_sym) == value
      end

      def encryptor_for(attr)
        encryptors[attr] ||= begin
          any_class(:encryptor_for, attr).with_context(self).tap do |encryptor|
            logger           = encryptor.logger
            logger.formatter = LogFormatter.new(self) if logger.respond_to?(:formatter=)
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