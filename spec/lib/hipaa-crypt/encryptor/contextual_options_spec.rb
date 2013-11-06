require 'spec_helper'

describe HipaaCrypt::Encryptor::ContextualOptions do

  let(:options_hash) { { foo: 'bar' } }
  let(:context) { Object.new }
  subject(:options) { described_class.new(options_hash).with_context(context) }

  describe '#initialize' do
    it 'should assign a options' do
      instance = described_class.allocate
      expect { instance.send(:initialize, options_hash) }
      .to change { instance.options }
          .to options_hash
    end
  end

  describe '#get' do
    it 'should call normalize object with the value from the options key' do
      expect(options)
      .to receive(:normalize_object)
          .with(options_hash[:foo])
      options.get(:foo)
    end

    context 'when #object returns nil' do
      context 'and when a block is given' do
        it 'should call the block' do
          expect(options)
          .to receive(:normalize_object)
              .and_return(nil)
          expect(options.get(:foo) { "hello world" }).to eq "hello world"
        end
      end

      context 'and when a block is not given' do
        it 'should be nil' do
          expect(options)
          .to receive(:normalize_object)
              .and_return(nil)
          options.get(:foo).should be_nil
        end
      end
    end
  end

  describe '#context' do
    context 'when a context is present' do
      it 'should return it' do
        context_double = double
        options.instance_variable_set(:@context, context_double)
        options.context.should eq context_double
      end
    end

    context 'when a context is not present' do
      it 'should raise an error' do
        options.instance_variable_set(:@context, nil)
        expect { options.context }.to raise_error HipaaCrypt::Encryptor::ContextMissing
      end
    end
  end

  describe '#with_context' do
    it 'should duplicate the object and set a context on the new object' do
      context_double = double
      new_options = options.with_context(context_double)
      new_options.object_id.should_not eq options.object_id
      new_options.context.should_not eq options.context
      new_options.context.should eq context_double
    end
  end

  describe '#normalize_object' do
    context 'given the object is a symbol' do
      it 'should call #normalize_symbol with the object' do
        object = :foo
        expect(options)
        .to receive(:normalize_symbol)
            .with(object)
        options.send(:normalize_object, object)
      end
    end

    context 'given the object is a proc' do
      it 'should call #normalize_symbol with the object' do
        object = proc {}
        expect(options)
        .to receive(:normalize_proc)
            .with(object)
        options.send(:normalize_object, object)
      end
    end

    context 'given the object is none of the above' do
      it 'should return the object' do
        object = double
        options.send(:normalize_object, object).should eq object
      end
    end
  end

  describe '#normalize_symbol' do
    it 'should invoke a send using a symbol on the context' do
      expect(context).to receive(:say_what_foo)
      options.send(:normalize_symbol, :say_what_foo)
    end
  end

  describe '#normalize_proc' do
    context 'when it has an arity' do
      it 'should call the proc with the context as an argument' do
        expect(context).to receive(:say_what_foo)
        options.send(:normalize_proc, ->(c){ c.say_what_foo })
      end
    end

    context 'when it does not have an arity' do
      it 'should call the proc without arguments' do
        expect(options.send :normalize_proc, ->{ "hello world" }).to eq "hello world"
      end
    end
  end

end