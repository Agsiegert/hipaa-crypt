module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord
        module Matchers

          # Returns whether or not a record matches the given conditions.
          # @param [Hash] conditions
          # @return [Boolean]
          def matches_conditions(conditions={})
            conditions.reduce(true) do |result, (attr, value)|
              result && matches_condition(attr, value)
            end
          end

          # Returns whether or not a record matches the given condition.
          # @param [Symbol/String] attr
          # @param [String/Regexp] value
          # @return [Boolean]
          def matches_condition(attr, value)
            case value
            when Regexp
              match_using_regexp(attr, value)
            else
              match_using_equality(attr, value)
            end
          end

          private

          def match_using_regexp(attr, value)
            instance_eval(&attr.to_sym) =~ value
          end

          def match_using_equality(attr, value)
            instance_eval(&attr.to_sym) == value
          end

        end
      end
    end
  end
end
