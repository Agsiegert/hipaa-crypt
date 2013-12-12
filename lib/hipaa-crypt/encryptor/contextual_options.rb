module HipaaCrypt
  class Encryptor

    ContextMissing = Class.new StandardError

    class ContextualOptions

      attr_reader :options

      def initialize(options)
        @options = options
      end

      def initialize_dup(other)
        @context = nil
      end

      # Return the current context.
      def context
        @context || raise(ContextMissing, 'context not set')
      end

      # Evaluate a key in the context.
      # @param [Symbol] key - the key we are trying to fetch
      # @param [Proc] block - the fallback block if the return is nil
      def get(key, &block)
        normalize_object(options[key]) || (block.call if block_given?)
      end

      # Returns a duplicate object with the new context.
      def with_context(context)
        dup.tap { |options| options.instance_variable_set(:@context, context) }
      end

      # Returns the raw value of an option.
      def raw_value(key)
        options[key]
      end

      alias [] raw_value

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