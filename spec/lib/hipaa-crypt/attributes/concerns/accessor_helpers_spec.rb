require 'spec_helper'

describe HipaaCrypt::Attributes::AccessorHelpers do

  subject(:model) do
    Class.new { include HipaaCrypt::Attributes }
  end

  before(:each) do
    model.class_eval { attr_accessor :test_method }
  end

  describe '#__get__' do
    context 'when an attribute is provided' do
      it 'returns the value of that attribute' do
        instance = model.new
        instance.test_method = 'attr_value'

        expect(instance.__get__(:test_method)).to eq 'attr_value'
      end
    end
  end

  describe '#__set__' do
    pending
  end

  describe '#read_encrypted_attr' do
    pending
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