require 'spec_helper'

describe HipaaCrypt::Attributes::ReEncryption do

  let(:model) do
    klass = Class.new do
      include HipaaCrypt::Attributes
      attr_accessor :foo, :bar, :baz
    end

    klass.encrypt :foo, :bar, :baz, old_options
    klass
  end

  context 'functions properly with a multi-encryptor' do

    let(:model) do
      klass = Class.new do
        include HipaaCrypt::Attributes
        attr_accessor :foo

        options_generator = proc do
          {   encryptor: [HipaaCrypt::AttrEncryptedEncryptor, HipaaCrypt::Encryptor].sample,
              iv: SecureRandom.hex,
              key: SecureRandom.hex,
              cipher: { name: :AES, key_length: 256, mode: [:OFB, :CBC, :ECB].sample }
          }
        end

        encrypt :foo, encryptor: HipaaCrypt::MultiEncryptor, chain: 10.times.map { options_generator.call }
      end
    end

    let(:value){ "Some really awesome value" }
    let(:instance){ model.new }

    it 'should properly re-encrypt' do
      instance.encrypted_foo = instance.conductor_for(:foo).encryptor_from_options.encryptors.last.encrypt value
      binding.pry
      expect { instance.re_encrypt :foo }.to change { instance.encrypted_foo }
    end

  end

  describe '#re_encrypt' do

    def generate_options
      {
          iv: SecureRandom.hex,
          key: SecureRandom.hex,
          cipher: {name: :AES, key_length: 256, mode: [:OFB, :CBC, :ECB].sample}
      }
    end

    def copy_encrypted_attrs(from, to)
      from.class.encrypted_attributes.map { |attr, encryptor| encryptor[:attribute] }.each do |var|
        to.send "#{var}=", from.send(var)
      end
    end

    def encrypted_values_match?(from, to)
      from.class.encrypted_attributes.map { |attr, encryptor| encryptor[:attribute] }.all? do |var|
        from.send(var) == to.send(var)
      end
    end

    def decrypted_values_match?(from, to)
      from.class.encrypted_attributes.keys.all? do |var|
        from.send(:__enc_get__, var) == to.send(:__enc_get__, var)
      end
    end

    let(:old_options) do
      generate_options
    end

    let(:new_options) do
      generate_options
    end

    let(:modified_model) do
      new_model = model.dup
      new_model.encrypt :foo, :bar, :baz, new_options
      new_model
    end

    let(:original_instance) do
      model.new
    end

    let(:new_instance) do
      modified_model.new
    end

    before(:each) do
      original_instance.foo = 'is something new'
      original_instance.bar = 'serves a drink'
      original_instance.baz = 'no idea'
      copy_encrypted_attrs original_instance, new_instance
    end

    context 'when :key is the only difference' do
      let(:new_options) { old_options.merge(key: SecureRandom.hex) }
      it 'should be able to re-encrypt using the new key' do
        new_instance.re_encrypt!(:foo, :bar, :baz, old_options)

        expect(encrypted_values_match? original_instance, new_instance).to be_false
        expect(decrypted_values_match? original_instance, new_instance).to be_true
      end
    end

    context 'when :key and :cipher are the only differences' do
      let(:new_options) { old_options.merge(key: SecureRandom.hex, cipher: {name: :AES, key_length: 192, mode: [:OFB, :CBC, :ECB].sample}) }
      it 'should be able to re-encrypt using the new key' do
        new_instance.re_encrypt!(:foo, :bar, :baz, old_options)

        expect(encrypted_values_match? original_instance, new_instance).to be_false
        expect(decrypted_values_match? original_instance, new_instance).to be_true
      end
    end

  end

end