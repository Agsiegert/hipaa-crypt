module HipaaCrypt
  class Encryptor
    class ContextualOptions

      attr_reader :options

      def initialize(options)
        @options = options
      end

      def initialize_dup(other)
        @context = nil
      end

      def context
        @context || raise(ArgumentError, 'context not set')
      end

      def get(key, &block)
        normalize_object(options[key]) || (block.call if block_given?)
      end

      def with_context(context)
        dup.tap { |options| options.instance_variable_set(:@context, context) }
      end

      def raw_value(key)
        options[key]
      end

      protected

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

      private

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