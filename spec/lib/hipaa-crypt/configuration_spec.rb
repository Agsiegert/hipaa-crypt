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
end