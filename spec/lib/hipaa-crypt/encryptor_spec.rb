require 'spec_helper'

describe HipaaCrypt::Encryptor do

  describe '.new' do
    it 'should assign options' do
      options = { foo: :bar, baz: :raz }
      instance = described_class.new(options)
      instance.options.should eq options
    end
  end

  describe '#encrypt' do

  end

  describe '#decrypt' do

  end

end
