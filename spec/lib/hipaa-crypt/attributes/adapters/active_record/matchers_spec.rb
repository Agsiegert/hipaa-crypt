require 'spec_helper'

describe  HipaaCrypt::Attributes::Adapters::ActiveRecord::Matchers do
  include_context 'an active record model'

  let(:record) { model.all.sample }

  describe '#matches_condition' do
    it 'should check against each condition' do
      pending
    end
  end

  describe '#matches_condition' do
    context 'when the value type is Regexp' do
      it 'calls #match_using_regexp' do
        expect(record).to receive(:match_using_regexp).with(:email, /[abc]/)
        record.matches_condition( :email, /[abc]/ )
      end
    end

    context 'when the value type is not Regexp' do
      it 'calls #match_using_equality' do
        expect(record).to receive(:match_using_equality).with(:email, :value)
        record.matches_condition( :email, :value )
      end
    end
  end

  describe '#match_using_regexp' do
    context 'when a match is found' do
      it 'should return true' do
        instance = model.create first_name: [SecureRandom.hex, "Something", SecureRandom.hex].join
        expect(instance.send :match_using_regexp, :first_name, /Something/).to be_true
      end
    end

    context 'when a match is not found' do
      it 'should return false' do
        instance = model.create first_name: [SecureRandom.hex, "Something", SecureRandom.hex].join
        expect(instance.send :match_using_regexp, :first_name, /Wrong/).to be_false
      end
    end
  end

  describe '#match_using_equality' do
    context 'when a match is found' do
      it 'should return true' do
        instance = model.create first_name: "Jason"
        expect(instance.send :match_using_equality, :first_name, "Jason").to be_true
      end
    end

    context 'when a match is not found' do
      it 'should return false' do
        instance = model.create first_name: "Jason"
        expect(instance.send :match_using_equality, :first_name, "Danny").to be_false
      end
    end
  end

end