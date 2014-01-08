require 'spec_helper'
require 'navigable_hash'

module HipaaCrypt
  describe MultiEncryptor do

    let(:local_key) { SecureRandom.hex }
    let(:local_iv) { SecureRandom.hex }
    let(:local_options) { { key: local_key, iv: local_iv } }
    let(:multi_encryptor) { MultiEncryptor.new local_options }

    before(:each) do
      allow(HipaaCrypt).to receive(:config).and_return( NavigableHash.new do |c|
        c.encryptor = HipaaCrypt::MultiEncryptor
        c.defaults = { encryptor: HipaaCrypt::Encryptor, key: SecureRandom.hex, cipher: { name: :AES, key_length: 256, mode: :CBC } }
        c.chain    = [ { encryptor: HipaaCrypt::AttrEncryptedEncryptor, key: SecureRandom.hex, iv: nil } ]
      end
      )
    end

    describe '#merge_defaults' do
      context 'given local options' do
        it 'merges the global defaults' do
          merged_options = multi_encryptor.merge_defaults local_options

          expect(merged_options[:chain]).not_to be_nil
          expect(merged_options[:encryptor]).to eq HipaaCrypt::Encryptor
          expect(merged_options[:key]).not_to eq local_key
          expect(merged_options[:iv]).to eq local_iv
        end
      end
    end

    describe '#build_encryptors' do
      it 'builds an array of encryptor instances' do
        encryptors = multi_encryptor.build_encryptors
        expect(encryptors).to be_a Array
      end

      it 'includes the encryptor from the encryptor chain' do
        encryptors = multi_encryptor.build_encryptors
        expect(
            encryptors.any? {|enc| enc.is_a? HipaaCrypt::AttrEncryptedEncryptor }
        ).to be_true
      end
    end

    describe '#encrypt' do
      it 'uses the first encryptor in the encryptors array' do
        expect(multi_encryptor.encryptors).to receive(:first).and_call_original
        multi_encryptor.encrypt('arg1')
      end
    end

    describe '#decrypt' do
      it 'trys to decrypt with each encryptor until it returns a value' do
        value = 'some_value'
        encrypted_value = multi_encryptor.encrypt value
        allow(multi_encryptor).to receive(:encryptors).and_return( multi_encryptor.encryptors.reverse )

        multi_encryptor.encryptors.each do |enc|
          expect(enc).to receive(:decrypt).with(encrypted_value).at_least(:once).and_call_original
          multi_encryptor.decrypt encrypted_value
        end
      end
    end

    describe '#decryptable?' do
      let(:value) { 'some_value' }

      context 'given a successful decryption' do
        it 'returns true' do
          encrypted_value = multi_encryptor.encrypt value
          expect(multi_encryptor.decryptable? encrypted_value).to eq true
        end
      end

      context 'given an unsuccessful decryption' do
        let(:multi_encryptor2) { MultiEncryptor.new }
        it 'returns false' do
          encrypted_value = multi_encryptor.encrypt value
          expect(multi_encryptor2.decryptable? encrypted_value).to eq false
        end
      end
    end

  end
end