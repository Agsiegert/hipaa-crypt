module HipaaCrypt
  module Attributes
    module Memoization

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