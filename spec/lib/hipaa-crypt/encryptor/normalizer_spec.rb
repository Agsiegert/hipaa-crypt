require 'spec_helper'

describe HipaaCrypt::Encryptor::Normalizer do

  describe '.new' do
    it 'should assign a context' do
      pending
    end
  end

  describe '#normalize_options' do
    it 'should return a hash' do
      pending
    end

    it 'should call #normalize_object with each value' do
      pending
    end
  end

  def normalize_object(object)
    context 'given the object is a symbol' do
      it 'should call #normalize_symbol with the object' do
        pending
      end
    end

    context 'given the object is a proc' do
      it 'should call #normalize_symbol with the object' do
        pending
      end
    end

    context 'given the object is none of the above' do
      it 'should return the object' do
        pending
      end
    end
  end

  def normalize_symbol(symbol)
    it 'should invoke a send using a symbol on the context' do
      pending
    end
  end

  def normalize_proc(proc)
    context 'when it has an arity' do
      it 'should call the proc with the context as an argument' do
        pending
      end
    end

    context 'when it does not have an arity' do
      it 'should call the proc without arguments' do
        pending
      end
    end
  end

end