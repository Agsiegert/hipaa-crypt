require 'spec_helper'
require 'securerandom'

describe HipaaCrypt::Attributes do

  subject(:model) do
    Class.new do
      include HipaaCrypt::Attributes
      attr_accessor :foo
    end
  end

  context 'implementations' do

    let(:instance) { model.new }

    shared_examples 'a functioning encryptor' do
      it 'should set an encrypted_value' do
        expect { instance.foo = 'bar' }.to change { instance.encrypted_foo }
        instance.foo = 'bar'
        expect(instance.foo).to eq 'bar'
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
        allow_any_instance_of(ActiveRecord::Base).to receive(:attributes)
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
        encryptor = HipaaCrypt::Encryptor
        conductor = HipaaCrypt::Attributes::Conductor.new( instance, { encryptor: encryptor, attribute: :foo } )
        allow(instance).to receive(:conductors).and_return({ foo: conductor })
        model.send(:set_encrypted_attribute, :foo, encryptor)
        expect(instance.send(:encryptor_for, :foo)).to eq encryptor
      end

    end

  end

end