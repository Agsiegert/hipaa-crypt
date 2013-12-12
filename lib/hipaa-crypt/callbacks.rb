module HipaaCrypt
  class Callbacks

    attr_reader :callbacks

    def initialize(callbacks)
      @callbacks = [callbacks].flatten.compact
    end

    # Run the provided callbacks
    # @param context - the value to modify in each callback
    def run(context)
      callbacks.reduce(context) do |output, callback|
        invoke_callback_on_context callback, output
      end
    end

    private

    def invoke_callback_on_context(callback, context)
      case callback
      when Symbol
        invoke_symbol_on_context(callback, context)
      when Proc
        invoke_proc_on_context(callback, context)
      else
        raise ArgumentError, 'callbacks must be symbols or procs'
      end
    end

    def invoke_symbol_on_context(symbol, context)
      context.send symbol
    end

    def invoke_proc_on_context(proc, context)
      proc.call(context)
    end

  end
end