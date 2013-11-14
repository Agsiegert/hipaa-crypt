require 'spec_helper'

describe  HipaaCrypt::Attributes::Adapters::ActiveRecord::Matchers do
  include_context 'an active record model'

  let(:record) { model.all.sample }

  describe '#matches_condition' do
    context 'when the value type is Regexp' do
      it 'calls #match_using_regexp' do
        expect(record).to receive(:match_using_regexp).with(:attr, /[abc]/)
        record.matches_condition( :attr, /[abc]/ )
      end
    end
  end
end