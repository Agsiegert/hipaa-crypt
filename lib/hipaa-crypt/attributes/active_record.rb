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

    end
  end
end