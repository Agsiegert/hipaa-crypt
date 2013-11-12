require 'active_support/concern'

module HipaaCrypt
  module Attributes
    module Memoization
      extend ActiveSupport::Concern

      module ClassMethods

        def __memoize_method__(method)
          alias_method "_#{method}_with_memoization_", method
          define_method(method) do |*args|
            __memoize__(method) do
              send "_#{method}_with_memoization_", *args
            end
          end
        end

      end

      private

      def __clear_memo__(attr)
        __memoizations__.delete attr
      end

      def __memoizations__
        @__memoizations__ ||= {}
      end

      def __memoize__(attr, &block)
        __memoizations__[attr] ||= (block.call if block_given?)
      end

    end
  end
end