require 'spec_helper'

describe HipaaCrypt::Encryptor do

  let(:options) { {key: SecureRandom.hex} }
  subject(:encryptor) { described_class.new(options) }

  describe '.new' do
    context 'if a cipher is provided' do
      let(:options) { {key: SecureRandom.hex, cipher: 'aes-256-cbc'} }
      it 'should call cipher= with the default options' do
        expect_any_instance_of(described_class)
        .to receive(:cipher=)
            .with(options[:cipher])
        allow_any_instance_of(described_class)
        .to receive(:cipher)
            .and_return(double iv_len: 16)
        described_class.new(options)
      end
    end

    context 'if a cipher is not provided' do
      it 'should call cipher= with the default options' do
        expect_any_instance_of(described_class)
        .to receive(:cipher=)
            .with('name' => :AES, 'key_length' => 256, 'mode' => :CBC)
        allow_any_instance_of(described_class)
        .to receive(:cipher)
            .and_return(double iv_len: 16)
        described_class.new(options)
      end
    end
  end

  describe '#decrypt' do
    let(:value) { %w{foo bar baz raz}.sample }
    let(:encrypted_value) { encryptor.encrypt value }

    it 'should successfully decrypt a value' do
      encryptor.decrypt(encrypted_value).should eq value
    end

    it 'should call decode with an encrypted string' do
      expect(encryptor).to receive(:decode)
                           .with(encrypted_value)
                           .and_call_original
      encryptor.decrypt(encrypted_value)
    end

    xit 'should call #setup cipher with #encrypt and the iv' do
      expect(encryptor).to receive(:setup_cipher).with(:decrypt).and_call_original
      encryptor.decrypt(encrypted_value)
    end

    context 'with callbacks' do
      let(:options) { {key: SecureRandom.hex, after_load: :to_s} }

      it 'should call run Callbacks using :after_load with the value' do
        encrypted_value
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
    let(:value) { %w{foo bar baz raz}.sample }

    context 'with callbacks' do
      let(:options) { {key: SecureRandom.hex, before_encrypt: :to_s} }

      it 'should call run Callbacks using :after_load with the value' do
        callbacks_double = double.tap { |cb| expect(cb).to receive(:run).with(value) }
        expect(HipaaCrypt::Callbacks)
        .to receive(:new)
            .with(:to_s)
            .and_return(callbacks_double)
        encryptor.encrypt value
      end

    end

    it 'should call #setup cipher with #encrypt' do
      expect(encryptor).to receive(:setup_cipher).with(:encrypt).and_call_original
      encryptor.encrypt("something")
    end

  end

  describe '#key' do
    context 'when options has a key' do
      it 'should return the value' do
        encryptor.key.should eq options[:key]
      end
    end
  end

  describe '#cipher=' do
    context 'when the value is a String' do
      it 'should try to initialize a OpenSSL::Cipher with the string' do
        encryptor # call to invoke cipher setter
        string = 'foo'
        expect(OpenSSL::Cipher).to receive(:new).with(string)
        encryptor.send(:cipher=, string)
      end
    end

    context 'when the value is a Hash' do
      it 'should try to initialize a OpenSSL::Cipher with the result of #cipher_string_from_hash' do
        hash = {foo: 'bar'}
        string = 'foo_bar'
        expect(encryptor).to receive(:cipher_string_from_hash).with(hash).and_return(string)
        expect(OpenSSL::Cipher).to receive(:new).with(string)
        encryptor.send(:cipher=, hash)
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
      opts = {key: SecureRandom.hex, iv: SecureRandom.hex}
      ecytor = described_class.new opts
      expect(ecytor.cipher).to receive(:iv=).with(opts[:iv]).and_call_original
      ecytor.send(:setup_cipher, :decrypt)
    end
  end

  describe '#cipher_string_from_hash' do
    it 'should return a properly formatted string' do
      string = encryptor.send(:cipher_string_from_hash, {mode: :Abc, name: :foo, key_length: 42})
      string.should eq 'foo-42-abc'
    end
  end

  describe '#decryptable?' do
    let(:options2) { { key: SecureRandom.hex } }
    let(:encryptor1) { HipaaCrypt::Encryptor.new options }
    let(:encryptor2) { HipaaCrypt::Encryptor.new options2 }
    let(:value) {'some_value'}

    context 'given a successful decryption' do
      it 'returns true' do
        encrypted_value = encryptor1.encrypt value
        expect(encryptor1.decryptable? encrypted_value).to eq true
      end
    end

    context 'given an unsuccessful decryption' do
      it 'returns false' do
        encrypted_value = encryptor1.encrypt value
        expect(encryptor2.decryptable? encrypted_value).to eq false
      end
    end
  end

  describe '#decode' do
    # 'tested in the public API'
  end

  describe '#deserialize' do
    # 'tested in the public API'
  end

  describe '#encode' do
    # 'tested in the public API'
  end

  describe '#serialize' do
    # 'tested in the public API'
  end

end
