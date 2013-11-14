require 'spec_helper'

describe HipaaCrypt::Attributes::Adapters::ActiveRecord::LogFormatter do

  include_context 'an active record model'
  let(:record) { model.all.sample }
  let(:subject) { described_class }

  describe '#call' do
    it 'returns a formatted string' do
      log_formatter = subject.new( record )
      expect(log_formatter.call 'high', :time, :progname, 'some msg').to eq "HIGH [time] #< id: #{record.id}> some msg\n"
    end
  end
end