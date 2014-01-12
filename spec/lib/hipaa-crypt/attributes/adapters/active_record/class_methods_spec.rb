require 'spec_helper'

describe HipaaCrypt::Attributes::Adapters::ActiveRecord::ClassMethods do

  include_context 'an active record model'

  [:re_encrypt, :re_encrypt!].each do |method|

    describe ".#{method}" do

      let(:args) { [:first_name] }

      it 'should return a re-encryptor' do
        expect(model.send method, *args).to be_an HipaaCrypt::Attributes::Adapters::ActiveRecord::ReEncryptor
      end

      it 'should run perform on the re-encryptor' do
        encryptor_double = double 'HipaaCrypt::Attributes::Adapters::ActiveRecord::ReEncryptor'
        allow(HipaaCrypt::Attributes::Adapters::ActiveRecord::ReEncryptor).to receive(:new).and_return(encryptor_double)
        expect(encryptor_double).to receive(:perform)
        model.send method, *args
      end
    end

  end

  describe '.relation' do
    it 'should extend with Relation additions' do
      expect(model.send(:relation).singleton_class.ancestors)
      .to include HipaaCrypt::Attributes::Adapters::ActiveRecord::RelationAdditions
    end
  end

  describe '.setter_defined?' do
    context 'when the column exists' do
      it 'should return true' do
        allow(model).to receive(:column_names).and_return(['foo'])
        expect(model.send(:setter_defined?, 'foo')).to eq true
      end
    end

    context 'when the column does not exist' do
      it 'should return false' do
        expect(model.send(:setter_defined?, 'foo')).to eq false
      end
    end
  end

  if ActiveRecord::VERSION::STRING < '4.0.0'

    describe '.all_attributes_exists?' do
      context 'when passed an encrypted attribute' do
        it 'should return true' do
          expect(model.send(:all_attributes_exists?, ['email', 'age'])).to be_true
        end
      end
    end

  end

end