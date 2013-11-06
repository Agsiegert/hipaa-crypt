require 'faker'

shared_context 'an active record model' do

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

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :sample_model
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

end