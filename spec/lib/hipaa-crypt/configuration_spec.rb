require 'spec_helper'

describe HipaaCrypt::Configuration do

  describe '#logger' do
    context 'when in a Rails environment' do
      let(:rails_logger){ double }
      before(:each){ stub_const('Rails', double(logger: rails_logger)) }
      it 'uses Rails.logger' do
        config = HipaaCrypt::Configuration.new

        expect(config.logger).to eq rails_logger
      end
    end

    context 'when not in a rails environment' do
      let(:fake_logger){ double }
      it 'should use a std out logger' do
        config = HipaaCrypt::Configuration.new
        expect(Logger).to receive(:new).with(STDOUT).and_return(fake_logger)

        expect(config.logger).to eq fake_logger
      end
    end
  end

  describe '#cipher' do
    context 'when no cipher is added' do
      it 'sets the default cipher' do
        default_cipher = { name: 'AES', length: 256, mode: 'CBC' }

        expect( HipaaCrypt::Configuration.new.cipher).to eq default_cipher
      end
    end

    context 'when a cipher is added' do
      it 'sets the  cipher' do
        cipher = { name: 'XYZ', length: 256, mode: 'ABC' }
        config = HipaaCrypt::Configuration.new
        config.cipher = cipher

        expect(config.cipher).to eq cipher
      end
    end
  end
end