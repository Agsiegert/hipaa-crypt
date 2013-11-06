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
        options = { key: SecureRandom.hex }
        encryptor = HipaaCrypt::Encryptor.new(options)
        iv = SecureRandom.hex
        value = 'attr_value'
        encrypted_value = encryptor.encrypt(value, iv).first
        instance.test_method = encrypted_value

        expect(instance.send :read_encrypted_attr, encrypted_value). to eq value
      end
    end

    context 'when the attribute passed is not encrypted' do

    end
  end

  describe '#write_encrypted_attr' do
    pending
  end

  describe '#read_iv' do
    pending
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