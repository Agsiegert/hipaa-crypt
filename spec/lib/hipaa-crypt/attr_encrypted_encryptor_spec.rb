require 'spec_helper'

describe HipaaCrypt::AttrEncryptedEncryptor do

  let(:options) { { key: SecureRandom.hex } }
  subject(:encryptor) { described_class.new(options) }

  describe '#decrypt' do
    let(:value) { %w{foo bar baz raz}.sample }
    let(:encrypt_return) { described_class.new(options).encrypt(value) }
    let(:encrypted_value) { encrypt_return.first }
    let(:iv) { encrypt_return.last }

    it 'should successfully decrypt a value' do
      encryptor.decrypt(encrypted_value, iv).should eq value
    end

    context 'when "encode: true" is in the options' do
      let(:options_with_encode) { { key: SecureRandom.hex, encode: true } }
      subject(:encryptor_with_encode) { described_class.new(options_with_encode) }
      let(:encrypt_with_encode_return) { encryptor_with_encode.encrypt(value) }
      let(:encrypted_value_with_encode) { encrypt_with_encode_return.first }
      let(:iv_with_encode) { encrypt_with_encode_return.last }

      it 'should call decode with an encrypted string' do
        expect(encryptor_with_encode).to receive(:decode)
                                         .with(encrypted_value_with_encode)
                                         .and_call_original
        encryptor_with_encode.decrypt(encrypted_value_with_encode, iv)
      end
    end

    context 'when "marshal: true" is in the options' do
      let(:options_with_marshal) { { key: SecureRandom.hex, marshal: true } }
      subject(:encryptor_with_marshal) { described_class.new(options_with_marshal) }
      let(:encrypt_with_marshal_return) { encryptor_with_marshal.encrypt(value) }
      let(:encrypted_value_with_marshal) { encrypt_with_marshal_return.first }
      let(:iv_with_marsal) { encrypt_with_marshal_return.last }

      it 'should call deserialize' do
        expect(encryptor_with_marshal).to receive(:deserialize).and_call_original
        encryptor_with_marshal.decrypt(encrypted_value_with_marshal, iv)
      end
    end

    it 'should call #setup cipher with #encrypt and the iv' do
      expect(encryptor).to receive(:setup_cipher).with(:decrypt, iv).and_call_original
      encryptor.decrypt(encrypted_value, iv)
    end

    context 'with callbacks' do
      let(:options) { { key: SecureRandom.hex, after_load: :to_s } }

      it 'should call run Callbacks using :after_load with the value' do
        encrypted_value
        callbacks_double = double.tap { |cb| expect(cb).to receive(:run).with(value) }
        expect(HipaaCrypt::Callbacks)
        .to receive(:new)
            .with(:to_s)
            .and_return(callbacks_double)
        encryptor.decrypt encrypted_value, iv
      end

    end
  end

  describe '#encrypt' do
    let(:value) { %w{foo bar baz raz}.sample }

    context 'with callbacks' do
      let(:options) { { key: SecureRandom.hex, before_encrypt: :to_s } }

      it 'should call run Callbacks using :before_encrypt with the value' do
        expect(HipaaCrypt::Callbacks)
        .to receive(:new)
            .with(:to_s)
            .and_call_original
        encryptor.encrypt value
      end

    end

    it 'should call #setup cipher with #encrypt and the iv' do
      iv = SecureRandom.hex
      expect(encryptor).to receive(:setup_cipher).with(:encrypt, iv).and_call_original
      encryptor.encrypt("something", iv)
    end

    context 'when "marshal: true" is in the options' do
      let(:options_with_marshal) { { key: SecureRandom.hex, marshal: true } }
      subject(:encryptor_with_marshal) { described_class.new(options_with_marshal) }

      it 'should call serialize' do
        expect(encryptor_with_marshal).to receive(:serialize).with(value).and_call_original
        encryptor_with_marshal.encrypt value
      end
    end

    context 'when "encode: true" is in the options' do
      let(:options_with_encode) { { key: SecureRandom.hex, encode: true } }
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
      encryptor.send(:setup_cipher, :decrypt, SecureRandom.hex)
    end

    it 'should call the cipher with the given mode' do
      expect(encryptor.cipher).to receive(:decrypt).and_call_original
      encryptor.send(:setup_cipher, :decrypt, SecureRandom.hex)
    end

    it 'should set the key on the cipher' do
      expect(encryptor.cipher).to receive(:key=).with(encryptor.key).and_call_original
      encryptor.send(:setup_cipher, :decrypt, SecureRandom.hex)
    end

    it 'should set the iv on the cipher using the provided iv' do
      iv = SecureRandom.hex
      expect(encryptor.cipher).to receive(:iv=).with(iv).and_call_original
      encryptor.send(:setup_cipher, :decrypt, iv)
    end

    context 'when iv is given as nil' do
      it 'should generate key and iv for the cipher using the provided key as password' do
        expect(encryptor.cipher).to receive(:pkcs5_keyivgen).with(options[:key]).and_call_original
        encryptor.send(:setup_cipher, :decrypt, nil)
      end
    end
  end

end
