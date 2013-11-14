require 'active_support/concern'

module HipaaCrypt
  module Attributes
    module Memoization
      extend ActiveSupport::Concern

      module ClassMethods

        def __memoize_method__(method)
          alias_method "_#{method}_without_memoization_", method
          define_method(method) do |*args|
            __memoize__(method) do
              send "_#{method}_without_memoization_", *args
            end
          end
        end

        def __clear_memoize_method__(method, options={})
          raise 'you must pass a valid method to with' unless (handler = options[:with]) && instance_method(handler)
          alias_method "_#{handler}_without_clearing_memoization_", handler
          define_method(handler) do |*args|
            __clear_memo__(method)
            send "_#{handler}_without_clearing_memoization_", *args
          end
        end

      end

      private

      def __clear_memo__(method)
        __memoizations__.delete method.to_sym
      end

      def __memoizations__
        @__memoizations__ ||= {}
      end

      def __memoize__(method, &block)
        __memoizations__[method.to_sym] ||= (block.call if block_given?)
      end

    end
  end
end