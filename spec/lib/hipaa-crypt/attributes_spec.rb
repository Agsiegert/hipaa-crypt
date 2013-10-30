require 'spec_helper'

describe HipaaCrypt::Attributes do

  let(:model) do
    Class.new { include HipaaCrypt::Attributes }
  end
  describe '.encrypt' do
    let(:attrs) { [:foo, :bar, :baz] }
    let(:options) { { run: :fast } }
    it 'should call define_encrypted_attr for each attribute with options' do
      attrs.each do |attr|
        expect(model).to receive(:define_encrypted_attr).with(attr, options)
      end
      model.encrypt *attrs, options
    end

    context "when options are not present" do
      it 'should use an empty hash as options' do
        attrs.each do |attr|
          expect(model).to receive(:define_encrypted_attr).with(attr, {})
        end
        model.encrypt *attrs
      end
    end
  end

  describe '.encrypted_attributes' do
    it 'should return a hash' do
      expect(model.encrypted_attributes).to be_a Hash
    end

    context 'if the superclass has the method' do
      subject(:supermodel) { Class.new { include HipaaCrypt::Attributes } }
      subject(:model) { Class.new supermodel }
      before(:each) do
        supermodel.set_encrypted_attribute :attr_a, "some super value"
        model.set_encrypted_attribute :attr_b, "some value"
      end
      it 'should merge its hash with the one from its superclass' do
        expect(model.encrypted_attributes).to include attr_a: "some super value",
                                                      attr_b: "some value"
      end
    end
  end

  describe '.define_encrypted_methods_for_attr' do

    before(:each) do
      allow(model).to receive(:method_added)
      model.send(:attr_accessor, :foo)
    end

    it 'should define an encrypting setter' do
      expect(model).to receive(:method_added).with(:foo=)
      model.send(:define_encrypted_methods_for_attr, :foo, :some_prefix_)
    end

    it 'should define an decrypting getter' do
      expect(model).to receive(:method_added).with(:foo)
      model.send(:define_encrypted_methods_for_attr, :foo, :some_prefix_)
    end

    context 'defined methods' do

      let(:instance){ model.new }
      let(:encryptor){ double encrypt: nil, decrypt: nil }

      before(:each) do
        allow(instance).to receive(:encryptor_for).and_return(encryptor)
        model.send(:define_unencrypted_methods_for_attr, :foo)
        model.send(:prefix_unencrypted_methods_for_attr, :encrypted_, :foo)
        model.send(:define_encrypted_methods_for_attr, :foo, :encrypted_)
      end

      describe 'encrypted attr getter' do
        it 'should use the attrs encryptor' do
          expect(instance).to receive(:encryptor_for).with(:foo).and_return(encryptor)
          instance.foo
        end

        it 'should use the attrs encryptor to decrypt a value' do
          encrypted_value = "some value"
          allow(instance).to receive(:encrypted_foo).and_return(encrypted_value)
          expect(encryptor).to receive(:decrypt).with(encrypted_value)
          instance.foo
        end

        it 'should be able to decrypt a value set by the setter' do
          allow(instance).to receive(:encryptor_for).and_return(HipaaCrypt::Encryptor.new key: SecureRandom.hex)
          instance.foo = "bar"
          expect { instance.foo }.to_not raise_error
        end
      end

      describe 'encrypted attr setter' do
        it 'should use the attrs encryptor' do
          expect(instance).to receive(:encryptor_for).with(:foo).and_return(encryptor)
          instance.foo = 'value'
        end
      end

      it 'should use the attrs encryptor to decrypt a value' do
        value = "some value"
        allow(instance).to receive(:encrypted_foo).and_return(value)
        expect(encryptor).to receive(:encrypt).with(value)
        instance.foo = value
      end

      it 'should be able to encrypt a value' do
        allow(instance).to receive(:encryptor_for).and_return(HipaaCrypt::Encryptor.new key: SecureRandom.hex)
        expect { instance.foo = "bar" }.to_not raise_error
      end
    end

  end

  describe '.define_encrypted_methods_for_attr_with_iv' do

    before(:each) do
      allow(model).to receive(:method_added)
      model.send(:attr_accessor, :foo)
      model.send(:attr_accessor, :foo_iv)
    end

    it 'should define an encrypting setter' do
      expect(model).to receive(:method_added).with(:foo=)
      model.send(:define_encrypted_methods_for_attr_with_iv, :foo, :some_prefix_)
    end

    it 'should define an decrypting getter' do
      expect(model).to receive(:method_added).with(:foo)
      model.send(:define_encrypted_methods_for_attr_with_iv, :foo, :some_prefix_)
    end

    context 'defined methods' do

      let(:instance){ model.new }
      let(:encryptor){ double encrypt: nil, decrypt: nil }

      before(:each) do
        allow(instance).to receive(:encryptor_for).and_return(encryptor)
        model.send(:define_unencrypted_methods_for_attr, :foo)
        model.send(:prefix_unencrypted_methods_for_attr, :encrypted_, :foo)
        model.send(:define_encrypted_methods_for_attr_with_iv, :foo, :encrypted_)
      end

      describe 'encrypted attr getter' do
        it 'should use the attrs encryptor' do
          expect(instance).to receive(:encryptor_for).with(:foo).and_return(encryptor)
          instance.foo
        end

        it 'should use the attrs encryptor to decrypt a value' do
          encrypted_value = "some value"
          allow(instance).to receive(:encrypted_foo).and_return(encrypted_value)
          expect(encryptor).to receive(:decrypt).with(encrypted_value)
          instance.foo
        end

        it 'should be able to decrypt a value set by the setter' do
          allow(instance).to receive(:encryptor_for).and_return(HipaaCrypt::Encryptor.new key: SecureRandom.hex, iv: SecureRandom.hex)
          instance.foo = "bar"
          expect { instance.foo }.to_not raise_error
        end
      end

      describe 'encrypted attr setter' do
        it 'should use the attrs encryptor' do
          expect(instance).to receive(:encryptor_for).with(:foo).and_return(encryptor)
          instance.foo = 'value'
        end
      end

      it 'should use the attrs encryptor to decrypt a value' do
        value = "some value"
        allow(instance).to receive(:encrypted_foo).and_return(value)
        expect(encryptor).to receive(:encrypt).with(value)
        instance.foo = value
      end

      it 'should be able to encrypt a value' do
        allow(instance).to receive(:encryptor_for).and_return(HipaaCrypt::Encryptor.new key: SecureRandom.hex, iv: SecureRandom.hex)
        expect { instance.foo = "bar" }.to_not raise_error
      end
    end

  end

  describe '.define_encrypted_methods_for_attr_with_settable_iv' do

    before(:each) do
      allow(model).to receive(:method_added)
      model.send(:attr_accessor, :foo)
      model.send(:attr_accessor, :foo_iv)
    end

    it 'should define an encrypting setter' do
      expect(model).to receive(:method_added).with(:foo=)
      model.send(:define_encrypted_methods_for_attr_with_settable_iv, :foo, :some_prefix_, :foo_iv)
    end

    it 'should define an decrypting getter' do
      expect(model).to receive(:method_added).with(:foo)
      model.send(:define_encrypted_methods_for_attr_with_settable_iv, :foo, :some_prefix_, :foo_iv)
    end

    context 'defined methods' do

      let(:instance){ model.new }
      let(:encryptor){ double encrypt: nil, decrypt: nil }

      before(:each) do
        allow(instance).to receive(:encryptor_for).and_return(encryptor)
        model.send(:define_unencrypted_methods_for_attr, :foo)
        model.send(:prefix_unencrypted_methods_for_attr, :encrypted_, :foo)
        model.send(:define_encrypted_methods_for_attr_with_settable_iv, :foo, :encrypted_, :foo_iv)
      end

      describe 'encrypted attr getter' do
        it 'should use the attrs encryptor' do
          expect(instance).to receive(:encryptor_for).with(:foo).and_return(encryptor)
          instance.foo
        end

        it 'should use the attrs encryptor to decrypt a value' do
          encrypted_value = "some value"
          allow(instance).to receive(:encrypted_foo).and_return(encrypted_value)
          allow(instance).to receive(:foo_iv).and_return(SecureRandom.hex)
          expect(encryptor).to receive(:decrypt).with(encrypted_value, instance.foo_iv)
          instance.foo
        end

        it 'should be able to decrypt a value set by the setter' do
          allow(instance).to receive(:encryptor_for).and_return(HipaaCrypt::Encryptor.new key: SecureRandom.hex)
          instance.foo = "bar"
          expect { instance.foo }.to_not raise_error
        end
      end

      describe 'encrypted attr setter' do
        it 'should use the attrs encryptor' do
          expect(instance).to receive(:encryptor_for).with(:foo).and_return(encryptor)
          instance.foo = 'value'
        end

        it 'should set the iv if nil' do
          allow(instance).to receive(:encryptor_for).and_return(HipaaCrypt::Encryptor.new key: SecureRandom.hex)
          expect { instance.foo = 'bar' }.to change { instance.foo_iv }
        end
      end

      it 'should use the attrs encryptor to decrypt a value' do
        value = "some value"
        allow(instance).to receive(:encrypted_foo).and_return(value)
        expect(encryptor).to receive(:encrypt).with(value)
        instance.foo = value
      end

      it 'should be able to encrypt a value' do
        allow(instance).to receive(:encryptor_for).and_return(HipaaCrypt::Encryptor.new key: SecureRandom.hex)
        expect { instance.foo = "bar" }.to_not raise_error
      end
    end

  end

  describe '.define_unencrypted_methods_for_attr' do

    context 'when the getter is not defined' do
      it 'should define a getter' do
        allow(model).to receive(:method_added)
        expect(model).to receive(:method_added).with(:foo)
        model.send(:define_unencrypted_methods_for_attr, :foo)
      end
    end

    context 'when the getter is defined' do
      before(:each) do
        model.send(:define_method, :foo) { "bar" }
      end

      it 'should not define a getter' do
        allow(model).to receive(:method_added)
        expect(model).not_to receive(:method_added).with(:foo)
        model.send(:define_unencrypted_methods_for_attr, :foo)
      end
    end

    context 'when the setter is not defined' do
      it 'should define a setter' do
        allow(model).to receive(:method_added)
        expect(model).to receive(:method_added).with(:foo=)
        model.send(:define_unencrypted_methods_for_attr, :foo)
      end
    end

    context 'when the setter is defined' do
      before(:each) do
        model.send(:define_method, :foo=) { "bar" }
      end

      it 'should not define a setter' do
        allow(model).to receive(:method_added)
        expect(model).not_to receive(:method_added).with(:foo=)
        model.send(:define_unencrypted_methods_for_attr, :foo)
      end
    end

  end

  describe '.prefix_unencrypted_methods_for_attr' do
    before(:each){ model.send(:define_unencrypted_methods_for_attr, :foo) }
    it 'should alias the getters and setters with a prefix' do

      getter_method = model.instance_method(:foo)
      setter_method = model.instance_method(:foo=)

      model.send(:prefix_unencrypted_methods_for_attr, :some_prefix_, :foo)

      model.instance_method(:some_prefix_foo).should eq getter_method
      model.instance_method(:some_prefix_foo=).should eq setter_method
    end
  end

end