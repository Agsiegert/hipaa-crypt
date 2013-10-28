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

end