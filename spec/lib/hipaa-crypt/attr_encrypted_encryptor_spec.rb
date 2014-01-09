require 'spec_helper'

describe HipaaCrypt::AttrEncryptedEncryptor do

  let(:options) { { key: SecureRandom.hex, iv: SecureRandom.hex } }
  subject(:encryptor) { described_class.new(options) }
  let(:value) { %w{foo bar baz raz}.sample }

  describe '#decrypt' do

    it 'should successfully decrypt a value' do
      encrypted_value = encryptor.encrypt value
      encryptor.decrypt(encrypted_value).should eq value
    end

    it 'should call #setup cipher with #encrypt and the iv' do
      encrypted_value = encryptor.encrypt value
      expect(encryptor).to receive(:setup_cipher).with(:decrypt).and_call_original
      encryptor.decrypt(encrypted_value)
    end

    context 'when "encode: true" is in the options' do
      let(:options_with_encode) { { key: SecureRandom.hex, iv: SecureRandom.hex, encode: true } }
      subject(:encryptor_with_encode) { described_class.new(options_with_encode) }
      let(:encrypted_value_with_encode) { encryptor_with_encode.encrypt value }

      it 'should call decode with an encrypted string' do
        expect(encryptor_with_encode).to receive(:decode)
        .with(encrypted_value_with_encode)
        .and_call_original
        encryptor_with_encode.decrypt(encrypted_value_with_encode)
      end
    end

    context 'when "marshal: true" is in the options' do
      let(:options_with_marshal) { { key: SecureRandom.hex,  iv: SecureRandom.hex, marshal: true } }
      subject(:encryptor_with_marshal) { described_class.new(options_with_marshal) }
      let(:encrypted_value_with_marshal) { encryptor_with_marshal.encrypt value }

      it 'should call deserialize' do
        expect(encryptor_with_marshal).to receive(:deserialize).and_call_original
        encryptor_with_marshal.decrypt(encrypted_value_with_marshal)
      end
    end


    context 'with callbacks' do
      let(:options) { { key: SecureRandom.hex, iv: SecureRandom.hex, after_load: :to_s } }
      it 'should call run Callbacks using :after_load with the value' do
        encrypted_value = encryptor.encrypt value
        callbacks_double = double.tap { |cb| expect(cb).to receive(:run).with(value) }
        expect(HipaaCrypt::Callbacks)
        .to receive(:new)
            .with(:to_s)
            .and_return(callbacks_double)
        encryptor.decrypt encrypted_value
      end

    end
  end

  describe '#encrypt' do

    context 'with callbacks' do
      let(:options) { { key: SecureRandom.hex, iv: SecureRandom.hex, before_encrypt: :to_s } }

      it 'should call run Callbacks using :before_encrypt with the value' do
        expect(HipaaCrypt::Callbacks)
        .to receive(:new)
            .with(:to_s)
            .and_call_original
        encryptor.encrypt value
      end

    end

    it 'should call #setup cipher with #encrypt and the iv' do
      expect(encryptor).to receive(:setup_cipher).with(:encrypt).and_call_original
      encryptor.encrypt("something")
    end

    context 'when "marshal: true" is in the options' do
      let(:options_with_marshal) { { key: SecureRandom.hex, iv: SecureRandom.hex, marshal: true } }
      subject(:encryptor_with_marshal) { described_class.new(options_with_marshal) }

      it 'should call serialize' do
        expect(encryptor_with_marshal).to receive(:serialize).with(value).and_call_original
        encryptor_with_marshal.encrypt value
      end
    end

    context 'when "encode: true" is in the options' do
      let(:options_with_encode) { { key: SecureRandom.hex, iv: SecureRandom.hex, encode: true } }
      subject(:encryptor_with_encode) { described_class.new(options_with_encode) }

      it 'should call encode' do
        expect(encryptor_with_encode).to receive(:encode).and_call_original
        encryptor_with_encode.encrypt value
      end
    end

  end

  describe '#setup_cipher' do
    it 'reset the cipher' do
      expect(encryptor.cipher).to receive(:reset).and_call_original
      encryptor.send(:setup_cipher, :decrypt)
    end

    it 'should call the cipher with the given mode' do
      expect(encryptor.cipher).to receive(:decrypt).and_call_original
      encryptor.send(:setup_cipher, :decrypt)
    end

    it 'should set the key on the cipher' do
      expect(encryptor.cipher).to receive(:key=).with(encryptor.key).and_call_original
      encryptor.send(:setup_cipher, :decrypt)
    end

    it 'should set the iv on the cipher using the provided iv' do
      iv = options[:iv]
      expect(encryptor.cipher).to receive(:iv=).with(iv).and_call_original
      encryptor.send(:setup_cipher, :decrypt)
    end

    context 'when iv is given as nil' do
      it 'should generate key and iv for the cipher using the provided key as password' do
        options = { key: SecureRandom.hex, iv: nil }
        encryptor = described_class.new options
        expect(encryptor.cipher).to receive(:pkcs5_keyivgen).with(options[:key]).and_call_original
        encryptor.send(:setup_cipher, :decrypt)
      end
    end
  end

end
