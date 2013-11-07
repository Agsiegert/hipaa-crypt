require 'spec_helper'

describe HipaaCrypt::Attributes::Memoization do

  subject(:model) do
    Class.new { include HipaaCrypt::Attributes }
  end

  let(:instance) { model.new }
  let(:attrs)    { {attr1: 'value1', attr2: 'value2'} }

  describe '#__clear_memo__' do
    context 'when a memoization hash with the given attribute exits' do
      it "deletes that attribute and it's value from the hash" do
        allow(instance).to receive(:__memoizations__).and_return attrs
        instance.send :__clear_memo__, :attr1

        expect(instance.send :__memoizations__).to eq({attr2: 'value2'})
      end
    end
  end

  describe '#__memoizations__' do
    context 'when a __memoizations__ contains attributes' do
      it 'returns a hash with the attributes and values' do
        allow(instance).to receive(:__memoizations__).and_return attrs

        expect(instance.send :__memoizations__).to eq attrs
      end
    end

    context 'when there is no __memoizations__ hash' do
      it 'sets and returns an empty hash' do
        expect(instance.send :__memoizations__).to eq( {} )
      end
    end
  end

  describe '#__memoize__' do
    context 'when the attribute is already memoized' do
      it 'returns the value of that attribute' do
        allow(instance).to receive(:__memoizations__).and_return attrs

        expect( instance.send(:__memoize__, :attr1) { 'some_value' } ).to eq 'value1'
      end
    end

    context 'when the attribute is not already memoized' do
      it 'memoizes the attribute with the given value' do
        expect( instance.send(:__memoize__, :attr1) { 'some_value' } ).to eq 'some_value'
      end
    end
  end

end