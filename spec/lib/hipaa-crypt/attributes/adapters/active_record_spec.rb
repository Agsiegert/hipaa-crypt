require 'spec_helper'

describe HipaaCrypt::Attributes::Adapters::ActiveRecord do

  include_context 'an active record model'

  let(:record) { model.all.sample }

  context 'queries' do

    describe '.where' do

      context 'when querying standard attributes' do

        it 'should not query encrypted attributes' do
          expect(model.where(age: 10).to_sql).to_not include 'encrypted_'
        end

      end

      context 'when querying encrypted attributes' do

        context 'when an iv and key are static' do
          it 'should query using encrypted attributes' do
            expect(model.where(email: 'foo@bar.com').to_sql).to include 'encrypted_'
          end
        end

        context 'when an iv is dynamic' do
          it 'should query using ids gathered from a manual decrypt' do
            expect(model.where(first_name: record.first_name).to_sql).to include '"id" IN '
          end
        end

      end

    end

    if ActiveRecord::VERSION::STRING >= '4.0.0'
      context 'rails 4' do
        describe '.find_by' do
          it 'should find a record' do
            expect(model.find_by email: record.email).to eq record
          end
        end

        describe '.find_or_create_by' do
          it 'should find a record' do
            expect(model.find_or_create_by email: record.email).to eq record
          end
        end

        describe '.find_or_initialize_by' do
          it 'should find a record' do
            expect(model.find_or_initialize_by email: record.email).to eq record
          end
        end
      end
    else
      describe '.find_by_attribute' do
        it 'should find a record' do
          expect(model.find_by_email record.email).to eq record
        end
      end

      describe '.find_or_create_by_attribute' do
        it 'should find a record' do
          expect(model.find_or_create_by_email record.email).to eq record
        end
      end

      describe '.find_or_initialize_by_attribute' do
        it 'should find a record' do
          expect(model.find_or_initialize_by_email record.email).to eq record
        end
      end
    end

    describe '#encryption_logger' do
      context 'when logger responds to #formatter=' do
        it 'returns a logger object' do
          expect(record.encryption_logger).to be_kind_of Logger
        end

        it 'does sets the formatter' do
          logger = double
          allow(HipaaCrypt.config).to receive(:logger).and_return logger
          expect(logger).to receive :formatter=
          record.encryption_logger
        end
      end

      context 'when logger does not respond to #formatter=' do
        xit 'does not set the formatter' do

        end
      end
    end

  end

end
