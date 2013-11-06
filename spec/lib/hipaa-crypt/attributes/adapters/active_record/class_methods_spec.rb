require 'spec_helper'

describe HipaaCrypt::Attributes::Adapters::ActiveRecord::ClassMethods do

  include_context 'an active record model'

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
      .to include HipaaCrypt::Attributes::Adapters::ActiveRecord::RelationAdditions
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