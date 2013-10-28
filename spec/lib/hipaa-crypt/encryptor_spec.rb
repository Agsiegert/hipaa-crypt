require 'spec_helper'

describe HipaaCrypt::Encryptor do

  let(:options) { { key: SecureRandom.hex } }
  subject(:encryptor) { described_class.new(options) }

  describe '.new' do
    context 'if a cipher is provided' do
      let(:options) { { key: SecureRandom.hex, cipher: 'aes-256-cbc' } }
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
            .with(name: :AES, key_length: 256, mode: :CBC)
        allow_any_instance_of(described_class)
        .to receive(:cipher)
            .and_return(double iv_len: 16)
        described_class.new(options)
      end
    end

    it 'should assign normalized options' do
      instance = described_class.new(options)
      instance.options.should be_an_instance_of HipaaCrypt::Encryptor::ContextualOptions
    end
  end

  describe '#encrypt' do
    let(:value) { %w{foo bar baz raz}.sample }

    it 'should call #run_before_hooks with the value' do
      expect(encryptor)
      .to receive(:run_before_hook)
          .with(value)
          .and_return(value)
      encryptor.encrypt value
    end

    it 'should reset the cipher' do
      expect(encryptor.cipher)
      .to receive(:reset)
          .and_call_original
      encryptor.encrypt(value)
    end

    it 'should tell the cipher its encrypting' do
      expect(encryptor.cipher)
      .to receive(:encrypt)
          .and_call_original
      encryptor.encrypt(value)
    end

    it 'should set the cipher key' do
      expect(encryptor.cipher)
      .to receive(:key=)
          .with(encryptor.key)
          .and_call_original
      encryptor.encrypt(value)
    end

    it 'should set the cipher iv' do
      iv = SecureRandom.uuid
      allow(encryptor)
      .to receive(:generate_iv)
          .and_return(iv)
      expect(encryptor.cipher)
      .to receive(:iv=)
          .with(iv)
          .and_call_original
      encryptor.encrypt(value)
    end

    it 'should call dump and encode with an encrypted value' do
      expect(encryptor).to receive(:dump_and_encode)
      encryptor.encrypt('foo')
    end

  end

  describe '#decrypt' do
    let(:value) { %w{foo bar baz raz}.sample }
    let(:encrypted_value) { described_class.new(options).encrypt(value) }

    it 'should successfully decrypt a value' do
      encryptor.decrypt(encrypted_value).should eq value
    end

    it 'should call dump and encode with an encrypted string' do
      expect(encryptor).to receive(:decode_and_load)
                           .with(encrypted_value)
                           .and_call_original
      encryptor.decrypt(encrypted_value)
    end

    it 'should reset the cipher' do
      expect(encryptor.cipher)
      .to receive(:reset)
          .and_call_original
      encryptor.decrypt(encrypted_value)
    end

    it 'should tell the cipher its encrypting' do
      expect(encryptor.cipher)
      .to receive(:decrypt)
          .and_call_original
      encryptor.decrypt(encrypted_value)
    end

    it 'should set the cipher key' do
      expect(encryptor.cipher)
      .to receive(:key=)
          .with(encryptor.key)
          .and_call_original
      encryptor.decrypt(encrypted_value)
    end

    it 'should set the cipher iv' do
      iv = encryptor.send(:decode_and_load, encrypted_value).iv
      expect(encryptor.cipher)
      .to receive(:iv=)
          .with(iv)
          .and_call_original
      encryptor.decrypt(encrypted_value)
    end

    it 'should call #run_after_hooks with the value' do
      expect(encryptor)
      .to receive(:run_after_hook)
          .with(value)
          .and_return(value)
      encryptor.decrypt encrypted_value
    end
  end

  describe '#cipher=' do
    context 'given the value is a String' do
      it 'should try to initialize a OpenSSL::Cipher with the string' do
        encryptor # call to invoke cipher setter
        string = 'foo'
        expect(OpenSSL::Cipher).to receive(:new).with(string)
        encryptor.send(:cipher=, string)
      end
    end

    context 'given the value is a Hash' do
      it 'should try to initialize a OpenSSL::Cipher with the result of #cipher_string_from_hash' do
        hash   = { foo: 'bar' }
        string = 'foo_bar'
        expect(encryptor).to receive(:cipher_string_from_hash).with(hash).and_return(string)
        expect(OpenSSL::Cipher).to receive(:new).with(string)
        encryptor.send(:cipher=, hash)
      end
    end
  end

  describe '#cipher_string_from_hash' do
    it 'should return a properly formatted string' do
      string = encryptor.send(:cipher_string_from_hash, { mode: :Abc, name: :foo, key_length: 42 })
      string.should eq 'foo-42-abc'
    end
  end

  describe '#decode_and_load' do
    it 'should be able to decode a base64 marshaled string' do
      value = Base64.encode64 Marshal.dump 'foo'
      expect { encryptor.send(:decode_and_load, value) }.to_not raise_error
    end

    it 'should be able to load a value from #dump_and_encode' do
      expect { encryptor.send :decode_and_load,
                              encryptor.send(:dump_and_encode, "foo", "iv")
      }.to_not raise_error
    end
  end

  describe '#dump_and_encode' do
    it 'should be a Base64 encoded marshaled string' do
      value = encryptor.send(:dump_and_encode, "foo", "iv")
      expect { Marshal.load Base64.decode64 value }.to_not raise_error
    end

    it 'should be marshaling an EncryptedObject' do
      expect(Marshal)
      .to receive(:dump)
          .with(an_instance_of HipaaCrypt::EncryptedObject)
          .and_call_original
      value = encryptor.send(:dump_and_encode, "foo", "iv")
    end
  end

  describe '#generate_iv' do
    context 'given options contains an iv' do
      let(:options) { { key: SecureRandom.hex, iv: SecureRandom.hex } }
      it 'should use the iv provided in the options' do
        encryptor.send(:generate_iv).should eq options[:iv]
      end
    end

    context 'given options do not contain an iv' do
      it 'should be a random value' do
        encryptor.send(:generate_iv).should_not eq encryptor.send(:generate_iv)
      end
    end
  end

  describe '#run_after_hook' do
    context 'when a hook is provided' do
      let(:options) { { key: SecureRandom.hex, iv: SecureRandom.hex, after_load: :upcase } }
      it 'should run the hook on the value' do
        encryptor.send(:run_after_hook, 'foo').should eq 'FOO'
      end
    end

    context 'when a hook is not provided' do
      it 'should return the value' do
        encryptor.send(:run_after_hook, 'foo').should eq 'foo'
      end
    end
  end

  describe '#run_before_hook' do
    context 'when a hook is provided' do
      let(:options) { { key: SecureRandom.hex, iv: SecureRandom.hex, before_encrypt: :upcase } }
      it 'should run the hook on the value' do
        encryptor.send(:run_before_hook, 'foo').should eq 'FOO'
      end
    end

    context 'when a hook is not provided' do
      it 'should return the value' do
        encryptor.send(:run_before_hook, 'foo').should eq 'foo'
      end
    end
  end

end
