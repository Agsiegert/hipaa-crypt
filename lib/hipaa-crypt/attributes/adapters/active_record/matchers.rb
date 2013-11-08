module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord
        module Matchers

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
  end
end
