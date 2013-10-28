module HipaaCrypt
  class Encryptor
    class ContextualOptions

      attr_reader :context, :options

      def initialize(options, context)
        @options = options
        @context = context
      end

      def get(key, context = self.context, &block)
        normalize_object(options[key]) || (block.call if block_given?)
      end

      private

      def normalize_object(object)
        case object
        when Symbol
          normalize_symbol(object)
        when Proc
          normalize_proc(object)
        else
          object
        end
      end

      def normalize_symbol(symbol)
        context.send symbol
      end

      def normalize_proc(proc)
        if proc.arity > 0
          proc.call(context)
        else
          proc.call
        end
      end

    end
  end
end