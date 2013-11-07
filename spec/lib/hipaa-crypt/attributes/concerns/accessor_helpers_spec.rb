require 'spec_helper'

describe HipaaCrypt::Attributes::AccessorHelpers do

  subject(:model) do
    Class.new { include HipaaCrypt::Attributes }
  end

  before(:each) do
    model.class_eval { attr_accessor :test_method }
  end

  let(:instance) { model.new }

  describe '#__get__' do
    context 'when an attribute is provided' do
      it 'returns the value of that attribute' do
        instance.test_method = 'attr_value'

        expect(instance.__get__ :test_method).to eq 'attr_value'
      end
    end
  end

  describe '#__set__' do
    context 'when an attribute and value are provided' do
      it 'sets the attribute value' do
        instance.test_method = 'attr_value'
        expect(instance.test_method).to eq 'attr_value'

        instance.__set__ :test_method, 'set_value'
        expect(instance.test_method).to eq 'set_value'
      end
    end
  end

  describe '#read_encrypted_attr' do
    context 'when the attribute passed is encrypted' do
      it 'returns the value of that attribute' do
        value = 'Foo bar baz'
        encryptor = HipaaCrypt::Encryptor.new attribute: :test_method
        allow(model).to receive(:encryptor_for).with(:test_method).and_return(encryptor)
        expect(instance).to receive(:test_method).and_return value

        expect(instance.send :read_encrypted_attr, :test_method).to eq value
      end
    end

    context 'when the attribute passed is not encrypted' do
      it 'returns an ArgumentError' do
        expect { instance.send :read_encrypted_attr, :test_method }.to raise_error ArgumentError
      end
    end
  end

  describe '#write_encrypted_attr' do
    context 'when an attribute and a value are provided' do
      before(:each) do
        encryptor = HipaaCrypt::Encryptor.new attribute: :test_method
        allow(model).to receive(:encryptor_for).with(:test_method).and_return(encryptor)
      end

      it 'calls #__clear_memo__ with the attribute' do
        expect(instance).to receive(:__clear_memo__).with :test_method
        instance.send :write_encrypted_attr, :test_method, :test_value
      end

      it 'calls #__set__ with the encrypted attribute and value' do
        expect(instance).to receive(:__set__).with(:test_method, :test_value)
        instance.send :write_encrypted_attr, :test_method, :test_value
      end
    end
  end

  describe '#read_iv' do
    before(:each) do
      encryptor = HipaaCrypt::Encryptor.new attribute: :test_method, iv: :some_iv
      allow(model).to receive(:encryptor_for).with(:test_method).and_return(encryptor)
    end

    it 'calls #__get__ with the attribute' do
      expect(instance).to receive(:__get__).with(:some_iv)
      instance.send :read_iv, :test_method
    end

    it 'returns the iv' do
      allow(instance).to receive(:some_iv).and_return :some_value
      expect(instance.send :read_iv, :test_method).to eq :some_value
    end
  end

  describe '#write_iv' do
    pending
  end

  describe '#encryptor_attribute_for' do
    pending
  end

  describe '#iv_attribute_for' do
    pending
  end

end