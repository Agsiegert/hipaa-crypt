require 'spec_helper'

describe HipaaCrypt::Attributes::ClassMethods do

  subject(:model) do
    Class.new do
      include HipaaCrypt::Attributes
      attr_accessor :foo
    end
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
        supermodel.send(:set_encrypted_attribute, :attr_a, "some super value")
        model.send(:set_encrypted_attribute, :attr_b, "some value")
      end
      it 'should merge its hash with the one from its superclass' do
        expect(model.encrypted_attributes).to include attr_a: "some super value",
                                                      attr_b: "some value"
      end
    end
  end

  describe '.define_encrypted_attr' do
    let(:options) { {some: :option} }
    let(:config)  { HipaaCrypt.config }
    before { allow(HipaaCrypt).to receive(:config).and_return config }

    it 'updates the options hash with HipaaCrypt#config' do
      expected_options = options.reverse_merge( config )
      expected_options[:original_attribute] = 'foo'
      expected_options[:attribute] = 'encrypted_foo'

      model.send(:define_encrypted_attr, :foo, options)
      actual_options = model.encrypted_attributes['foo']

      expect(expected_options).to eq actual_options
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

  #  context 'defined methods' do
  #
  #
  #    #let(:options) { { key: SecureRandom.hex, iv: '1234'} }
  #    let(:instance) { model.new }
  #    #let(:encryptor) { double encrypt: nil, decrypt: nil, options: options }
  #    #let(:encryptor) { HipaaCrypt::Encryptor.new options }
  #
  #    before(:each) do
  #      model.encrypt :foo
  #      allow(model).to receive(:encryptor_for).and_return(encryptor)
  #      allow(instance).to receive(:encryptor_for).and_return(encryptor)
  #      model.send(:alias_unencrypted_methods_for_attr, :foo)
  #      model.send(:define_encrypted_methods_for_attr, :foo)
  #    end
  #
  #    describe 'encrypted attr getter' do
  #      it 'should use the attrs encryptor' do
  #        #expect(instance).to receive(:encrypted_foo).and_return("1234\nsomething")
  #        expect(instance).to receive(:encryptor_for).with(:foo).and_call_original
  #        instance.foo = 'bar'
  #        instance.foo
  #      end
  #
  #      it 'should use the attrs encryptor to decrypt a value' do
  #        encrypted_value = "iv\nsome-value"
  #        allow(instance).to receive(:encrypted_foo).and_return(encrypted_value)
  #        expect(encryptor).to receive(:decrypt).with('some-value', 'iv')
  #        instance.foo
  #      end
  #
  #      it 'should be able to decrypt a value set by the setter' do
  #        encryptor = HipaaCrypt::Encryptor.new key: SecureRandom.hex, attribute: :foo, attribute: :encrypted_foo
  #        allow(instance).to receive(:encryptor_for).and_return encryptor
  #        instance.foo = "bar"
  #        expect { instance.foo }.to_not raise_error
  #      end
  #    end
  #
  #    describe 'encrypted attr setter' do
  #      it 'should use the attrs encryptor' do
  #        expect(instance).to receive(:encryptor_for).with(:foo).and_return(encryptor)
  #        instance.foo = 'value'
  #      end
  #
  #      it 'should leave null value as null' do
  #        instance.foo = nil
  #        expect(instance.foo).to eq nil
  #      end
  #    end
  #
  #    it 'should use the attrs encryptor to decrypt a value' do
  #      value = "some value"
  #      allow(instance).to receive(:encrypted_foo).and_return(value)
  #      expect(encryptor).to receive(:encrypt).with(value)
  #      instance.foo = value
  #    end
  #
  #    it 'should be able to encrypt a value' do
  #      encryptor = HipaaCrypt::Encryptor.new key: SecureRandom.hex, attribute: :foo, attribute: :encrypted_foo
  #      allow(instance).to receive(:encryptor_for).and_return encryptor
  #      expect { instance.foo = "bar" }.to_not raise_error
  #    end
  #  end
  #
  end


  describe '.setter_defined?' do
    context 'when a setter exists' do
      it 'should be true' do
        expect(model.send(:setter_defined?, :foo)).to be_true
      end
    end

    context 'when a setter does not exist' do
      it 'should be true' do
        expect(model.send(:setter_defined?, :bar)).to be_false
      end
    end
  end

end
