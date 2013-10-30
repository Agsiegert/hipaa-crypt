require 'spec_helper'

describe HipaaCrypt::Attributes do

  let(:model) do
    Class.new { include HipaaCrypt::Attributes }
  end

  context 'implementations' do

    let(:instance){ model.new }

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
    end

    context 'with a static iv' do
      before (:each)do
        model.encrypt :foo, key: SecureRandom.hex, iv: '1234567890123456'
      end
      it_should_behave_like 'a functioning encryptor'
    end

    context 'with an iv setter' do
      before (:each)do
        model.send(:attr_accessor, :foo_iv)
        model.encrypt :foo, key: SecureRandom.hex, iv: :foo_iv
      end
      it_should_behave_like 'a functioning encryptor'
    end

    context 'with a generated iv' do
      before (:each)do
        model.send(:attr_accessor, :foo_iv)
        model.encrypt :foo, key: SecureRandom.hex
      end
      it_should_behave_like 'a functioning encryptor'
    end

  end

  describe HipaaCrypt::Attributes::ClassMethods do

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
          expect(encryptor.options.options).to eq hello: :world
        end
        model.send(:define_encrypted_attr, :foo, hello: :world)
      end

      it 'should call define' do
        expect(model).to receive(:define_unencrypted_methods_for_attr).with(:foo).and_call_original
        model.send(:define_encrypted_attr, :foo, {})
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

        let(:instance) { model.new }
        let(:encryptor) { double encrypt: nil, decrypt: nil }

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

        let(:instance) { model.new }
        let(:encryptor) { double encrypt: nil, decrypt: nil }

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

        let(:instance) { model.new }
        let(:encryptor) { double encrypt: nil, decrypt: nil }

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
            expect(encryptor).to receive(:decrypt).with(encrypted_value)
            instance.foo
          end

          it 'should be able to decrypt a value set by the setter' do
            allow(instance)
            .to receive(:encryptor_for)
                .and_return HipaaCrypt::Encryptor.new(key: SecureRandom.hex, iv: :foo_iv).with_context(instance)
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
      before(:each) { model.send(:define_unencrypted_methods_for_attr, :foo) }
      it 'should alias the getters and setters with a prefix' do

        getter_method = model.instance_method(:foo)
        setter_method = model.instance_method(:foo=)

        model.send(:prefix_unencrypted_methods_for_attr, :some_prefix_, :foo)

        model.instance_method(:some_prefix_foo).should eq getter_method
        model.instance_method(:some_prefix_foo=).should eq setter_method
      end
    end

    describe '.setter_defined?' do
      context 'when a setter exists' do
        before(:each){ model.send :attr_accessor, :foo }
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

    describe '.setter_for' do
      it 'should append an equals to the attr' do
        expect(model.send(:setter_for, :foo)).to eq :foo=
      end
    end

  end

  context 'instance methods' do

    let(:instance) { model.new }

    describe '#encryptor_for' do
      it 'should return an encryptor for a given attribute' do
        encryptor = HipaaCrypt::Encryptor.new
        allow(encryptor).to receive(:with_context).and_return(encryptor)
        model.set_encrypted_attribute(:foo, encryptor)
        expect(instance.send(:encryptor_for, :foo)).to eq encryptor
      end

      it 'the encryptor should have a context of the instance' do
        encryptor = HipaaCrypt::Encryptor.new
        model.set_encrypted_attribute(:foo, encryptor)
        expect(instance.send(:encryptor_for, :foo).context).to eq instance
      end
    end

  end

  describe '#re_encrypt' do
    require 'securerandom'

    let(:old_options) do
      {
          iv: '9Plkd4vMBsMcQRsl5nD+/TJ41RQX4Q2xmlykrP0nizWqia84nd7c4e8eCFs=',
          key: '1738a4f3eae8a310da7024c032b6451d',
          cipher: {name: :AES, key_length: 256, mode: :OFB}
      }
    end
    let(:object_with_encryption) do
      klass = Class.new { include HipaaCrypt::Attributes }
      klass.encrypt :foo, :bar, :baz, old_options
      stub_const('ClassWithEncryption', klass)
      ClassWithEncryption.new
    end
    let(:foo_bar_baz) { ['foo', 'bar', 'baz'] }
    let(:old_unencrypted_foo_bar_baz) { ["foo's value", "bar's value", "baz's value"] }
    let(:old_encrypted_foo_bar_baz) do
      encrypted_values = []
      0.upto(2) do |n|
        eval("object_with_encryption.#{foo_bar_baz[n]} = old_unencrypted_foo_bar_baz[#{n}]")
        eval("encrypted_values << object_with_encryption.encrypted_#{foo_bar_baz[n]}")
      end
      encrypted_values
    end

    before(:each) do
      object_with_encryption
      old_encrypted_foo_bar_baz
      object_with_encryption.instance_variable_set(:@encryptors, nil)
      object_with_encryption.class.instance_variable_set(:@encrypted_attributes, nil)
    end

    context 'when "key" is the only difference' do
      let(:object_with_new_encryption) do
        new_options = old_options.merge key: 'fa8ccb8ff6ca60a2a9c1db4b2356da18'
        object_with_encryption.class.encrypt(:foo, :bar, :baz, new_options)
        object_with_encryption
      end

      it 'should be able to re-encrypt using the new key' do
        # This is just to confirm that the values WERE encrypted before re-encryption.
        0.upto(2) {|n| expect(old_encrypted_foo_bar_baz[n]).not_to eq old_unencrypted_foo_bar_baz[n]}

        old_key = { key: '1738a4f3eae8a310da7024c032b6451d' }

        object_with_new_encryption.re_encrypt(:foo, :bar, :baz, old_key)
        0.upto(2) do |n|
          expect(eval("object_with_new_encryption.#{foo_bar_baz[n]}")).to eq old_unencrypted_foo_bar_baz[n]
          expect(eval("object_with_new_encryption.encrypted_#{foo_bar_baz[n]}")).not_to eq(old_encrypted_foo_bar_baz[n])
        end
      end
    end

    context 'when "key" and "cipher" mode are the only differences' do
      let(:object_with_new_encryption) do
        new_options = old_options.merge({ key: 'fa8ccb8ff6ca60a2a9c1db4b2356da18', cipher: {name: :AES, key_length: 256, mode: :CBC} })
        object_with_encryption.class.encrypt(:foo, :bar, :baz, new_options)
        object_with_encryption
      end

      it 'should be able to re-encrypt using the new key and the new cipher mode' do
        old_key_and_cipher_mode = {
            key: '1738a4f3eae8a310da7024c032b6451d',
            cipher: { mode: :OFB }
        }

        object_with_new_encryption.re_encrypt(:foo, :bar, :baz, old_key_and_cipher_mode)
        0.upto(2) do |n|
          expect(eval("object_with_new_encryption.#{foo_bar_baz[n]}")).to eq old_unencrypted_foo_bar_baz[n]
          expect(eval("object_with_new_encryption.encrypted_#{foo_bar_baz[n]}")).not_to eq(old_encrypted_foo_bar_baz[n])
        end
      end
    end
  end

end