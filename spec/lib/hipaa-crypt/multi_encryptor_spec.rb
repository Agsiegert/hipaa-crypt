require 'spec_helper'

module HipaaCrypt
  describe MultiEncryptor do

    let(:local_options) { {key: 'other_key', iv: 'other_iv', encryptor: 'SomeEncryptor'} }
    let(:multi_encryptor) { MultiEncryptor.new local_options }

    before(:all) do
      HipaaCrypt.config do |c|
        c.encryptor = HipaaCrypt::MultiEncryptor
        c.defaults = { encryptor: HipaaCrypt::Encryptor, key: 'some_key', cipher: { name: :AES, key_length: 256, mode: :CBC } }
        c.chain    = [ { encryptor: HipaaCrypt::AttrEncryptedEncryptor, key: 'some_key', iv: nil } ]
      end
    end

    describe '#merge_defaults' do
      context 'given local options' do
        it 'merges the global defaults' do
          merged_options = multi_encryptor.merge_defaults local_options

          expect(merged_options[:chain]).not_to be_nil
          expect(merged_options[:encryptor]).to eq 'SomeEncryptor'
          expect(merged_options[:key]).to eq 'other_key'
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

  end
end