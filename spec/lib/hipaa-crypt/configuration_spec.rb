require 'spec_helper'

describe HipaaCrypt::Configuration do

  describe '#extractable_options' do
    it 'should be true' do
      expect(HipaaCrypt::Configuration.new.extractable_options?).to be_true
    end
  end

end