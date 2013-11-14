require 'spec_helper'

describe HipaaCrypt::Attributes::AccessorHelpers do

  subject(:model) do
    Class.new { include HipaaCrypt::Attributes }
  end

  before(:each) do
    model.class_eval { attr_accessor :test_method }
  end

  let(:instance) { model.new }

  let(:setup_encryptor) do
    encryptor = HipaaCrypt::Encryptor.new attribute: :encrypted_test_method, iv: :some_iv
    allow(model).to receive(:encryptor_for).with(:test_method).and_return(encryptor)
  end

  describe '#__enc_get__' do
    context 'when an attribute is provided' do
      it 'returns the value of that attribute' do
        expect(instance).to receive(:_decrypt_test_method).and_return 'attr_value'
        expect(instance.__enc_get__ :test_method).to eq 'attr_value'
      end
    end
  end

  describe '#__enc_set__' do
    context 'when an attribute and value are provided' do
      it 'sets the attribute value' do
        expect(instance).to receive(:_encrypt_test_method)
        instance.__enc_set__(:test_method, 'set_value')
      end
    end
  end

  describe '#read_encrypted_attr' do
    context 'when the attribute passed is encrypted' do
      it 'returns the value of that attribute' do
        value = 'Foo bar baz'
        setup_encryptor
        expect(instance).to receive(:encrypted_test_method).and_return value

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
        encryptor = HipaaCrypt::Encryptor.new attribute: :test_method, iv: :some_iv
        allow(model).to receive(:encryptor_for).with(:test_method).and_return(encryptor)
      end

      it 'calls #__clear_memo__ with the attribute' do
        instance.send :write_encrypted_attr, :test_method, :test_value
      end

      it 'calls #__set__ with the encrypted attribute and value' do
        expect(instance).to receive(:test_method=).with(:test_value)
        instance.send :write_encrypted_attr, :test_method, :test_value
      end
    end
  end

  describe '#read_iv' do
    before(:each) do
      setup_encryptor
    end

    it 'calls #__get__ with the attribute' do
      expect(instance).to receive(:some_iv)
      instance.send :read_iv, :test_method
    end

    it 'returns the iv' do
      allow(instance).to receive(:some_iv).and_return :some_value
      expect(instance.send :read_iv, :test_method).to eq :some_value
    end
  end

  describe '#write_iv' do

    it 'calls #__set__ with the iv and value' do
      setup_encryptor
      expect(instance).to receive(:some_iv=).with(:some_value)
      instance.send :write_iv, :test_method, :some_value
    end
  end

  describe '#encryptor_attribute_for' do
    it 'returns the value of the encrypted attribute' do
      setup_encryptor
      expect(instance.send :encrypted_attribute_for, :test_method).to eq :encrypted_test_method
    end
  end

  describe '#iv_attribute_for' do
    it 'returns the iv for an encrypted attribute' do
      setup_encryptor
      expect(instance.send :iv_attribute_for, :test_method).to eq :some_iv
    end
  end

end