require 'spec_helper'

describe HipaaCrypt do

  describe '.config' do
    context 'when a cipher is added' do
      it 'sets Configuration#chiper' do
        cipher = { name: 'XYZ', length: 256, mode: 'ABC' }
        config = HipaaCrypt.config { |c| c.cipher =  cipher }

        expect(config.cipher).to eq cipher
      end
    end

    context 'when a cipher is not added' do
      it 'sets a default cipher' do
        default_cipher = { name: 'AES', length: 256, mode: 'CBC' }
        HipaaCrypt.instance_variable_set(:@config, nil)
        config = HipaaCrypt.config

        expect(config.cipher).to eq default_cipher
      end
    end

    context 'when a key is added' do
      it 'sets Configuration#key' do
        key = 'a secret key'
        config = HipaaCrypt.config { |c| c.key = key }

        expect(config.key).to eq key
      end
    end
  end
end
