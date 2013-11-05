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
        t.timestamps
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

    [:re_encrypt, :re_encrypt!].each do |method|

      describe ".#{method}" do

        let(:args) { [:first_name] }
        let(:result_double) { double }

        it 'call .re_encrypt_query_from_args and return a query' do
          allow(model).to receive(:re_encrypt_in_batches).and_return(result_double)
          expect(model).to receive(:re_encrypt_query_from_args).with(args).and_return(model)
          expect(model.send method, *args).to eq result_double
        end

        it "should should call .re_encrypt_in_batches with #{method} and args" do
          allow(model).to receive(:re_encrypt_query_from_args).and_return(model)
          allow(model).to receive(:re_encrypt_in_batches).with(method, *args).and_return(result_double)
          expect(model.send method, *args).to eq result_double
        end
      end

    end

    describe '.re_encrypt_in_batches' do
      let(:mock_collection) { 5.times.map { double encrypt_method: true, save!: true } }
      let(:args) { [:email, key: SecureRandom.hex, iv: SecureRandom.hex] }

      before(:each) do
        allow(model).to receive(:find_each) { |&block| mock_collection.each(&block) }
      end

      it 'should call each instance with the method and args' do
        mock_collection.each do |mock_instance|
          expect(mock_instance).to receive(:encrypt_method).with(*args).and_return(true)
          expect(mock_instance).to receive(:save!).and_return(true)
        end
        model.re_encrypt_in_batches(:encrypt_method, *args)
      end

      it 'should print success' do
        expect(model).to receive(:print_success).at_least :once
        model.re_encrypt_in_batches(:encrypt_method, *args)
      end

      context 'when the item fails re-encryption' do
        let(:mock_instance) { mock_collection.first }
        before(:each) { allow(mock_instance).to receive(:encrypt_method).and_return(false) }

        it 'should not call save' do
          expect(mock_instance).to_not receive(:save!)
          model.re_encrypt_in_batches(:encrypt_method, *args)
        end

        it 'should print fail' do
          expect(model).to receive(:print_fail)
          model.re_encrypt_in_batches(:encrypt_method, *args)
        end
      end

      context 'when the item fails to save' do
        let(:mock_instance) { mock_collection.first }
        before(:each) { allow(mock_instance).to receive(:save!).and_return(false) }
        it 'should print fail' do
          expect(model).to receive(:print_fail)
          model.re_encrypt_in_batches(:encrypt_method, *args)
        end
      end
    end

    describe '.print_success' do
      let(:message) { "\e[0;32;49m.\e[0m" }
      context 'when not silent' do
        before { allow(HipaaCrypt.config).to receive(:silent_re_encrypt) { false } }
        it 'should call print' do
          expect(model).to receive(:print).with message
          model.send(:print_success)
        end
      end

      context 'when silent' do
        before { allow(HipaaCrypt.config).to receive(:silent_re_encrypt) { true } }
        it 'should not call print' do
          expect(model).to_not receive(:print)
          model.send(:print_success)
        end
      end
    end

    describe '.print_fail' do
      context 'when silent' do
        let(:message) { "\e[0;31;49mF\e[0m" }
        context 'when not silent' do
          before { allow(HipaaCrypt.config).to receive(:silent_re_encrypt) { false } }
          it 'should call print' do
            expect(model).to receive(:print).with message
            model.send(:print_fail)
          end
        end

        context 'when silent' do
          before { allow(HipaaCrypt.config).to receive(:silent_re_encrypt) { true } }
          it 'should not call print' do
            expect(model).to_not receive(:print)
            model.send(:print_fail)
          end
        end
      end
    end

    describe '.puts_counts' do
      context 'when silent' do
        let(:success_count){ Random.rand(0..10000) }
        let(:fail_count){ Random.rand(0..10000) }
        let(:messages) { ["Re-Encrypted \e[0;32;49m#{success_count}\e[0m #{model.name} records",
                         "\e[0;31;49m#{fail_count}\e[0m Failed"] }
        context 'when not silent' do
          before { allow(HipaaCrypt.config).to receive(:silent_re_encrypt) { false } }
          it 'should call puts' do
            expect(model).to receive(:puts).with *messages
            model.send(:puts_counts, success_count, fail_count)
          end
        end

        context 'when silent' do
          before { allow(HipaaCrypt.config).to receive(:silent_re_encrypt) { true } }
          it 'should not call puts' do
            expect(model).to_not receive(:puts)
            model.send(:puts_counts, success_count, fail_count)
          end
        end
      end
    end

    describe '.re_encrypt_query_from_args' do
      context 'given an lt arg' do
        it 'should return a proper active record query for <' do
          query = model.send(:re_encrypt_query_from_args, [updated_at_lt: 5000])
          expect(query).to be_a ActiveRecord::Relation
          query.to_sql.should include 'updated_at', '<', '5000'
          expect { query.to_a }.to_not raise_error
        end
      end

      context 'given an gt arg' do
        it 'should return a proper active record query for >' do
          query = model.send(:re_encrypt_query_from_args, [updated_at_gt: 5000])
          expect(query).to be_a ActiveRecord::Relation
          query.to_sql.should include 'updated_at', '>', '5000'
          expect { query.to_a }.to_not raise_error
        end
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
