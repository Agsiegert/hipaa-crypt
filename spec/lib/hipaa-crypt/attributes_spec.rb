require 'spec_helper'
require 'securerandom'

describe HipaaCrypt::Attributes do

  subject(:model) do
    Class.new { include HipaaCrypt::Attributes }
  end

  context 'implementations' do

    let(:instance) { model.new }

    shared_examples 'a functioning encryptor' do
      it 'should set an encrypted_value' do
        expect { instance.foo = 'bar' }.to change { instance.encrypted_foo }
      end

      it 'should encrypt successfully' do
        instance.foo = 'bar'
      end

      it 'should decrypt successfully' do
        instance.foo = 'bar'
        instance.foo.should eq 'bar'
      end

      it 'should be able to successfully change a value' do
        instance.foo = 'bar'
        instance.foo.should eq 'bar'
        instance.foo = 'baz'
        instance.foo.should eq 'baz'
        instance.foo = 'raz'
        instance.foo.should eq 'raz'
      end
    end

    context 'with a static iv' do
      before (:each) do
        model.encrypt :foo, key: SecureRandom.hex, iv: '1234567890123456'
      end
      it_should_behave_like 'a functioning encryptor'
    end

    context 'with an iv setter' do
      before (:each) do
        model.send(:attr_accessor, :foo_iv)
        model.encrypt :foo, key: SecureRandom.hex, iv: :foo_iv
      end
      it_should_behave_like 'a functioning encryptor'
    end

    context 'with a generated iv' do
      before (:each) do
        model.send(:attr_accessor, :foo_iv)
        model.encrypt :foo, key: SecureRandom.hex
      end
      it_should_behave_like 'a functioning encryptor'
    end

  end

  describe '.included' do
    context 'when the base is a descendant of active record' do
      let(:model) do
        stub_const 'ActiveRecord::Base', Class.new
        allow(ActiveRecord::Base).to receive(:after_initialize)
        Class.new(ActiveRecord::Base) { include HipaaCrypt::Attributes }
      end

      it 'should include the active record extension' do
        expect(model.ancestors).to include HipaaCrypt::Attributes::Adapters::ActiveRecord
      end
    end

    context 'when the base is a descendant of anything supported' do
      it 'should not include the active record extension' do
        expect(model.ancestors).to_not include HipaaCrypt::Attributes::Adapters::ActiveRecord
      end
    end
  end

  context 'instance methods' do

    let(:instance) { model.new }

    describe '#encryptor_for' do
      it 'should return an encryptor for a given attribute' do
        encryptor = HipaaCrypt::Encryptor.new
        allow(encryptor).to receive(:with_context).and_return(encryptor)
        model.send(:set_encrypted_attribute, :foo, encryptor)
        expect(instance.send(:encryptor_for, :foo)).to eq encryptor
      end

      it 'the encryptor should have a context of the instance' do
        encryptor = HipaaCrypt::Encryptor.new
        model.send(:set_encrypted_attribute, :foo, encryptor)
        expect(instance.send(:encryptor_for, :foo).context).to eq instance
      end
    end

  end

end