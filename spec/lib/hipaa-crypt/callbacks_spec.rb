require 'spec_helper'

describe HipaaCrypt::Callbacks do

  subject(:args) { [] }
  subject(:callbacks) { described_class.new(args) }

  describe '#initialize' do
    subject(:callbacks) { described_class.allocate }
    context 'when callbacks is nil' do
      it 'should return an empty array' do
        expect { callbacks.send(:initialize, nil) }
        .to change { callbacks.callbacks }
            .to []
      end
    end

    context 'when callbacks is not an array' do
      it 'should return an array' do
        expect { callbacks.send(:initialize, :something) }
        .to change { callbacks.callbacks }
            .to [:something]
      end
    end

    context 'when callbacks is an array' do
      it 'should return an array' do
        expect { callbacks.send(:initialize, [:something]) }
        .to change { callbacks.callbacks }
            .to [:something]
      end
    end
  end

  describe '#run' do
    let(:args) { [:foo, :bar, :baz] }
    it 'should call #invoke_callback_on_context with each callback with the context' do
      context = double
      args.each do |arg|
        expect(callbacks).to receive(:invoke_callback_on_context).with(arg, context).and_return(context)
      end
      callbacks.run(context)
    end

    context 'with a list of callbacks' do
      let(:args) do
        [
          proc { |obj| obj + 15 },
          :to_s,
          :reverse,
          :to_i
        ]
      end

      it 'should properly return a callback' do
        context = 0
        callbacks.run(context).should eq 51
      end

    end
  end

  describe '#invoke_callback_on_context' do
    context 'when the callback is a symbol' do
      it 'should call #invoke_symbol_on_context' do
        symbol = :foo
        context = double
        expect(callbacks).to receive(:invoke_symbol_on_context).with(symbol, context)
        callbacks.send :invoke_callback_on_context, symbol, context
      end
    end

    context 'when the callback is a proc' do
      it 'should call #invoke_proc_on_context' do
        proc = proc {}
        context = double
        expect(callbacks).to receive(:invoke_proc_on_context).with(proc, context)
        callbacks.send :invoke_callback_on_context, proc, context
      end
    end

    context 'when the callback is none of the above' do
      it 'should raise an error' do
        expect { callbacks.send(:invoke_callback_on_context, Object.new, double) }.to raise_error ArgumentError
      end
    end
  end

  describe '#invoke_symbol_on_context' do
    it 'should send a method to the context' do
      context = double
      expect(context).to receive(:foo)
      callbacks.send(:invoke_symbol_on_context, :foo, context)
    end
  end

  describe '#invoke_proc_on_context' do
    it 'should call the with the context as an argument' do
      context = double
      expect(context).to receive(:foo)
      callbacks.send(:invoke_proc_on_context, ->(obj){ obj.foo }, context)
    end
  end

end
