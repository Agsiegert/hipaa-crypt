require 'spec_helper'

describe HipaaCrypt::Attributes::ClassMethods do

  subject(:model) do
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

  describe '.define_encrypted_attr' do
    it 'should call set_encrypted_attribute with the attr and an encryptor' do
      expect(model).to receive(:set_encrypted_attribute).with :foo, an_instance_of(HipaaCrypt::Encryptor) do |attr, encryptor|
        expect(encryptor.options.options).to include hello: :world
      end
      model.send(:define_encrypted_attr, :foo, hello: :world) rescue nil
    end

    it 'should call define' do
      expect(model).to receive(:define_unencrypted_methods_for_attr).with(:foo).and_call_original
      model.send(:define_encrypted_attr, :foo, {})
    end

    it 'should call prefix_unencrypted_methods_for_attr' do
      options = { prefix: 'a_prefix_' }
      expect(model).to receive(:alias_unencrypted_methods_for_attr).with(:foo).and_call_original
      model.send(:define_encrypted_attr, :foo, options)
    end

    context 'when a setter is defined and there is an iv' do
      it 'should call define_encrypted_methods_for_attr_with_settable_iv' do
        options = { iv: :some_iv, prefix: 'a_prefix_' }
        allow(model).to receive(:setter_defined?).with(options[:iv]).and_return true
        expect(model).to receive(:define_encrypted_methods_for_attr_with_settable_iv).with(:foo)
        model.send(:define_encrypted_attr, :foo, options)
      end
    end

    context 'when there is an iv but no setter is defined' do
      it 'should call define_encrypted_methods_for_attr_with_iv' do
        options = { iv: :some_iv, prefix: 'a_prefix_' }
        expect(model).to receive(:define_encrypted_methods_for_attr_with_iv).with(:foo)
        model.send(:define_encrypted_attr, :foo, options)
      end
    end

    context 'when there is no iv' do
      it 'should call define_encrypted_methods_for_attr' do
        options = { prefix: 'a_prefix_' }
        expect(model).to receive(:define_encrypted_methods_for_attr).with(:foo)
        model.send(:define_encrypted_attr, :foo, options)
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
      model.send(:define_encrypted_methods_for_attr, :foo)
    end

    it 'should define an decrypting getter' do
      expect(model).to receive(:method_added).with(:foo)
      model.send(:define_encrypted_methods_for_attr, :foo)
    end

    context 'defined methods' do

      let(:options) do
        HipaaCrypt::Encryptor::ContextualOptions.new attribute: :foo, attribute: :encrypted_foo
      end
      let(:instance) { model.new }
      let(:encryptor) { double encrypt: nil, decrypt: nil, options: options }

      before(:each) do
        allow(model).to receive(:encryptor_for).and_return(encryptor)
        allow(instance).to receive(:encryptor_for).and_return(encryptor)
        model.send(:define_unencrypted_methods_for_attr, :foo)
        model.send(:alias_unencrypted_methods_for_attr, :foo)
        model.send(:define_encrypted_methods_for_attr, :foo)
      end

      describe 'encrypted attr getter' do
        it 'should use the attrs encryptor' do
          expect(instance).to receive(:encrypted_foo).and_return('something')
          expect(instance).to receive(:encryptor_for).with(:foo).and_return(encryptor)
          instance.foo
        end

        it 'should use the attrs encryptor to decrypt a value' do
          encrypted_value = "iv\nsome-value"
          allow(instance).to receive(:encrypted_foo).and_return(encrypted_value)
          expect(encryptor).to receive(:decrypt).with('some-value', 'iv')
          instance.foo
        end

        it 'should be able to decrypt a value set by the setter' do
          encryptor = HipaaCrypt::Encryptor.new key: SecureRandom.hex, attribute: :foo, attribute: :encrypted_foo
          allow(instance).to receive(:encryptor_for).and_return encryptor
          instance.foo = "bar"
          expect { instance.foo }.to_not raise_error
        end
      end

      describe 'encrypted attr setter' do
        it 'should use the attrs encryptor' do
          expect(instance).to receive(:encryptor_for).with(:foo).and_return(encryptor)
          instance.foo = 'value'
        end

        it 'should leave null value as null' do
          instance.foo = nil
          expect(instance.foo).to eq nil
        end
      end

      it 'should use the attrs encryptor to decrypt a value' do
        value = "some value"
        allow(instance).to receive(:encrypted_foo).and_return(value)
        expect(encryptor).to receive(:encrypt).with(value)
        instance.foo = value
      end

      it 'should be able to encrypt a value' do
        encryptor = HipaaCrypt::Encryptor.new key: SecureRandom.hex, attribute: :foo, attribute: :encrypted_foo
        allow(instance).to receive(:encryptor_for).and_return encryptor
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
      model.send(:define_encrypted_methods_for_attr_with_iv, :foo)
    end

    it 'should define an decrypting getter' do
      expect(model).to receive(:method_added).with(:foo)
      model.send(:define_encrypted_methods_for_attr_with_iv, :foo)
    end

    context 'defined methods' do

      let(:options) do
        HipaaCrypt::Encryptor::ContextualOptions.new attribute: :foo, attribute: :encrypted_foo
      end
      let(:instance) { model.new }
      let(:encryptor) { double encrypt: nil, decrypt: nil, options: options }

      before(:each) do
        allow(model).to receive(:encryptor_for).and_return(encryptor)
        allow(instance).to receive(:encryptor_for).and_return(encryptor)
        model.send(:define_unencrypted_methods_for_attr, :foo)
        model.send(:alias_unencrypted_methods_for_attr, :foo)
        model.send(:define_encrypted_methods_for_attr_with_iv, :foo)
      end

      describe 'encrypted attr getter' do
        it 'should use the attrs encryptor' do
          expect(instance).to receive(:encrypted_foo).and_return('something')
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
          encryptor = HipaaCrypt::Encryptor.new key: SecureRandom.hex, iv: SecureRandom.hex, attribute: :foo, attribute: :encrypted_foo
          allow(instance).to receive(:encryptor_for).and_return encryptor
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
        encryptor = HipaaCrypt::Encryptor.new key: SecureRandom.hex, iv: SecureRandom.hex, attribute: :foo, attribute: :encrypted_foo
        allow(instance).to receive(:encryptor_for).and_return encryptor
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
      model.send(:define_encrypted_methods_for_attr_with_settable_iv, :foo)
    end

    it 'should define an decrypting getter' do
      expect(model).to receive(:method_added).with(:foo)
      model.send(:define_encrypted_methods_for_attr_with_settable_iv, :foo)
    end

    context 'defined methods' do

      let(:options) do
        HipaaCrypt::Encryptor::ContextualOptions.new attribute: :foo, attribute: :encrypted_foo, iv: :foo_iv
      end
      let(:instance) { model.new }
      let(:encryptor) { double encrypt: nil, decrypt: nil, options: options }

      before(:each) do
        allow(model).to receive(:encryptor_for).and_return(encryptor)
        allow(instance).to receive(:encryptor_for).and_return(encryptor)
        model.send(:define_unencrypted_methods_for_attr, :foo)
        model.send(:alias_unencrypted_methods_for_attr, :foo)
        model.send(:define_encrypted_methods_for_attr_with_settable_iv, :foo)
      end

      describe 'encrypted attr getter' do
        it 'should use the attrs encryptor' do
          expect(instance).to receive(:encrypted_foo).and_return('something')
          expect(instance).to receive(:encryptor_for).with(:foo).and_return(encryptor)
          instance.foo
        end

        it 'should use the attrs encryptor to decrypt a value' do
          encrypted_value = "some value"
          allow(instance).to receive(:foo_iv).and_return('iv')
          allow(instance).to receive(:encrypted_foo).and_return(encrypted_value)
          expect(encryptor).to receive(:decrypt).with(encrypted_value, 'iv')
          instance.foo
        end

        it 'should be able to decrypt a value set by the setter' do
          encryptor = HipaaCrypt::Encryptor.new(
            key: SecureRandom.hex, iv: :foo_iv, attribute: :foo, attribute: :encrypted_foo
          ).with_context(instance)
          allow(instance).to receive(:encryptor_for).and_return(encryptor)
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
          encryptor = HipaaCrypt::Encryptor.new(
            key: SecureRandom.hex, iv: :foo_iv, attribute: :foo, attribute: :encrypted_foo
          ).with_context(instance)
          allow(instance).to receive(:encryptor_for).and_return(encryptor)
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
        encryptor = HipaaCrypt::Encryptor.new(
          key: SecureRandom.hex, iv: :foo_iv, attribute: :foo, attribute: :encrypted_foo
        ).with_context(instance)
        allow(instance).to receive(:encryptor_for).and_return(encryptor)
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

  describe '.alias_unencrypted_methods_for_attr' do
    let(:options) do
      HipaaCrypt::Encryptor::ContextualOptions.new attribute: :foo, attribute: :foo_enc_attr
    end
    let(:instance) { model.new }
    let(:encryptor) { double encrypt: nil, decrypt: nil, options: options }

    before(:each) do
      allow(model).to receive(:encryptor_for).and_return(encryptor)
      model.send(:define_unencrypted_methods_for_attr, :foo)
    end

    it 'should alias the getters and setters with a prefix' do

      getter_method = model.instance_method(:foo)
      setter_method = model.instance_method(:foo=)

      model.send(:alias_unencrypted_methods_for_attr, :foo)

      model.instance_method(:foo_enc_attr).should eq getter_method
      model.instance_method(:foo_enc_attr=).should eq setter_method
    end
  end

  describe '.setter_defined?' do
    context 'when a setter exists' do
      before(:each) { model.send :attr_accessor, :foo }
      it 'should be true' do
        expect(model.send(:setter_defined?, :foo)).to be_true
      end
    end

    context 'when a setter does not exist' do
      it 'should be true' do
        expect(model.send(:setter_defined?, :foo)).to be_false
      end
    end
  end

end
