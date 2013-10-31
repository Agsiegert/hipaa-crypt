require 'spec_helper'
require 'faker'
require 'logger'

describe HipaaCrypt::Attributes::ActiveRecord do

  before(:all) do
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Base.logger       = Logger.new('/dev/null')
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Schema.define do

      create_table :sample_model do |t|
        t.binary :encrypted_email
        t.binary :encrypted_first_name
        t.binary :encrypted_first_name_iv
        t.binary :encrypted_last_name
        t.string :age
      end

      add_index :sample_model, :encrypted_email, unique: true
    end
  end

  let(:model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'sample_model'
      enc_key         = "areallylongandsecurekeythatnoonewillknow"
      enc_iv          = "astaticivtobeusedonthings"

      include HipaaCrypt::Attributes
      encrypt :email, key: enc_key, iv: enc_iv # static iv
      encrypt :first_name, key: enc_key, iv: :encrypted_first_name_iv # dynamic attribute iv
      encrypt :last_name, key: enc_key # dynamic inline iv
    end
  end

  before(:each) do
    unless model.count > 100
      100.times do
        first_name  = Faker::Name.first_name
        last_name   = Faker::Name.last_name
        domain      = Faker::Internet.domain_name
        random_seed = SecureRandom.hex(5)
        email       = "#{first_name}.#{last_name}.#{random_seed}@#{domain}"
        age         = (5..65).to_a.sample
        model.create email: email, first_name: first_name, last_name: last_name, age: age
      end
    end
  end

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

  end

  describe HipaaCrypt::Attributes::ActiveRecord::ClassMethods do

    describe '.re_encrypt' do

      let(:mock_collection) { 5.times.map { double re_encrypt: true, save: true } }
      let(:args) { [:email, key: SecureRandom.hex, iv: SecureRandom.hex] }

      context 'with a double' do

        before(:each) do
          all_mock = double
          allow(all_mock).to receive(:find_in_batches) { |&block| [mock_collection].each(&block) }
          allow(model).to receive(:all).and_return all_mock
        end

        it 'should call #re_encrypt on each item with the given options' do
          mock_collection.each do |mock_instance|
            expect(mock_instance).to receive(:re_encrypt).with(*args)
            expect(mock_instance).to receive(:save)
          end
          model.re_encrypt(*args)
        end

        it 'should not fail with an exception' do
          expect(mock_collection.sample).to receive(:re_encrypt) { raise Exception, 'something happened' }
          expect { model.re_encrypt(*args) }.to_not raise_error
        end

      end

      it 'should re_encrypt data' do
        old_options = model.encryptor_for(:email).options.options
        model.encrypt :email, key: SecureRandom.hex
        model.re_encrypt :email, old_options
        expect { model.all.map(&:email) }.to_not raise_error
        model.delete_all
      end

    end

    describe '.re_encrypt!' do

      let(:mock_collection) { 5.times.map { double re_encrypt: true, save!: true } }
      let(:args) { [:email, key: SecureRandom.hex, iv: SecureRandom.hex] }

      before(:each) do
        all_mock = double
        allow(all_mock).to receive(:find_in_batches) { |&block| [mock_collection].each(&block) }
        allow(model).to receive(:all).and_return all_mock
      end

      it 'should call #re_encrypt on each item with the given options' do
        mock_collection.each do |mock_instance|
          expect(mock_instance).to receive(:re_encrypt).with(*args)
          expect(mock_instance).to receive(:save!)
        end
        model.re_encrypt!(*args)
      end

      it 'should fail with an exception' do
        expect(mock_collection.sample).to receive(:re_encrypt) { raise Exception, 'something happened' }
        expect { model.re_encrypt!(*args) }.to raise_error
      end

    end

    describe '.relation' do
      it 'should extend with Relation additions' do
        expect(model.send(:relation).singleton_class.ancestors)
        .to include HipaaCrypt::Attributes::ActiveRecord::RelationAdditions
      end
    end

    describe '.setter_defined?' do
      context 'when the column exists' do
        it 'should return true' do
          allow(model).to receive(:column_names).and_return(['foo'])
          expect(model.send(:setter_defined?, 'foo')).to eq true
        end
      end

      context 'when the column does not exist' do
        it 'should return false' do
          expect(model.send(:setter_defined?, 'foo')).to eq false
        end
      end
    end

    if ActiveRecord::VERSION::STRING < '4.0.0'

      describe '.all_attributes_exists?' do
        context 'when passed an encrypted attribute' do
          it 'should return true' do
            expect(model.send(:all_attributes_exists?, ['email', 'age'])).to be_true
          end
        end
      end

    end

  end

  describe HipaaCrypt::Attributes::ActiveRecord::RelationAdditions do
    # Tested by the queries context
  end

end
