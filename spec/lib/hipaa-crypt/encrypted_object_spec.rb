require 'spec_helper'

describe HipaaCrypt::EncryptedObject do

  describe '#initialize' do
    let(:value) { "value" }
    let(:iv) { SecureRandom.hex }
    subject(:instance) { described_class.allocate }

    it 'should set a value' do
      expect { instance.send(:initialize, value, iv) }
      .to change { instance.value }
          .to value
    end

    it 'should set an iv' do
      expect { instance.send(:initialize, value, iv) }
      .to change { instance.iv }
          .to iv
    end
  end

end