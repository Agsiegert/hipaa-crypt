require 'spec_helper'

describe HipaaCrypt::Attributes::Adapters::ActiveRecord do

  context 'functions properly with a multi-encryptor' do

    include_context 'an active record model'
    let(:record) { model.all.sample }
    let(:subject) { described_class }

    let(:model) do
      Class.new(ActiveRecord::Base) do

        def self.generate_options(options={})
          { encryptor: [HipaaCrypt::AttrEncryptedEncryptor, HipaaCrypt::Encryptor].sample,
            key:       SecureRandom.hex,
            cipher:    { name: :AES, key_length: 256, mode: [:OFB, :CBC, :ECB].sample }
          }.merge(options)
        end

        include HipaaCrypt::Attributes
        self.table_name = 'sample_model'

        encrypt :email, encryptor: HipaaCrypt::MultiEncryptor, chain: 10.times.map { generate_options(iv: SecureRandom.hex) }
        encrypt :first_name, encryptor: HipaaCrypt::MultiEncryptor, defaults: { iv: :encrypted_first_name_iv }, chain: 10.times.map { generate_options }
        encrypt :last_name, encryptor: HipaaCrypt::MultiEncryptor, chain: 10.times.map { generate_options }
      end
    end

    let(:instance) { model.new }

    it 'should properly re-encrypt email' do
      value          = "jason.waldrip@example.com"
      past_conductor = HipaaCrypt::Attributes::Conductor.new(instance, instance.conductor_for(:email).encryptor_from_options.encryptors.last.options)
      past_conductor.encrypt value
      old_val = instance.encrypted_email
      instance.re_encrypt(:email)
      expect(old_val).to_not eq(instance.encrypted_email)
    end

    it 'should properly re-encrypt first_name' do
      value          = "Jason"
      past_conductor = HipaaCrypt::Attributes::Conductor.new(instance, instance.conductor_for(:first_name).encryptor_from_options.encryptors.last.options)
      past_conductor.encrypt value
      old_val = instance.encrypted_first_name
      instance.re_encrypt(:first_name)
      expect(old_val).to_not eq(instance.encrypted_first_name)
    end

    it 'should properly re-encrypt last_name' do
      value          = "Waldrip"
      past_conductor = HipaaCrypt::Attributes::Conductor.new(instance, instance.conductor_for(:last_name).encryptor_from_options.encryptors.last.options)
      past_conductor.encrypt value
      old_val = instance.encrypted_last_name
      instance.re_encrypt(:last_name)
      expect(old_val).to_not eq(instance.encrypted_last_name)
    end

    it 'should properly re-encrpyt the class' do
      model.encrypted_attributes.keys.each do |attr|
        model.all.each do |instance|
          conductor = instance.conductor_for(attr).sub_conductors.last
          conductor.encrypt instance.read_attribute(attr)
          instance.extend(HipaaCrypt::Attributes::Adapters::ActiveRecord::CallbackSkipper)
          instance.save_without_callbacks
        end
      end

      expect { model.re_encrypt }.to change { model.all.map(&:encrypted_attributes) }
    end

    context 'notifications' do
      it 'should properly notify' do
        allow(HipaaCrypt.config).to receive(:silent_re_encrypt).and_return(false)
        allow_any_instance_of(HipaaCrypt::Attributes::Adapters::ActiveRecord::ReEncryptor).to receive(:freeze)
        expect_any_instance_of(HipaaCrypt::Attributes::Adapters::ActiveRecord::ReEncryptor).to receive(:puts).exactly(2).times
        expect_any_instance_of(HipaaCrypt::Attributes::Adapters::ActiveRecord::ReEncryptor).to receive(:print).exactly(10).times
        model.re_encrypt!
      end
    end

  end

end