require 'spec_helper'

module HipaaCrypt
  module Attributes

    describe Conductor do

      let(:instance) do
        model = Class.new do
          include HipaaCrypt::Attributes
          attr_accessor :encrypted_foo
        end
        model.new
      end

      let(:value) { 'foo' }

      before do
        allow(HipaaCrypt).to receive(:config).and_return(NavigableHash.new do |c|
          c.key = SecureRandom.hex
          c.cipher = {name: :AES, key_length: 256, mode: :CBC}
        end
                             )
      end

      describe '#joined_iv?' do
        it 'returns true if the iv is not in the options' do
          options = {foo: :bar}
          conductor = Conductor.new instance, options
          expect(conductor.joined_iv?).to eq true
        end

        it 'returns false if the iv is included in the options' do
          options = {iv: 'some_iv'}
          conductor = Conductor.new instance, options
          expect(conductor.joined_iv?).to eq false
        end
      end

      describe '#encryptor_from_options' do
        context 'given an encryptor type in the options' do
          it 'creates a new instance with the given options' do
            options = {encryptor: HipaaCrypt::Encryptor, original_attribute: :foo}
            conductor = Conductor.new instance, options
            encryptor = conductor.encryptor_from_options options

            expect(encryptor).to be_a HipaaCrypt::Encryptor
            expect(encryptor.options["original_attribute"]).to eq :foo
          end
        end
      end

      describe '#encrypt' do

        let(:options) { {encryptor: HipaaCrypt::Encryptor, attribute: 'encrypted_foo'} }

        context 'given a joined iv' do
          it 'calls #encrypt_with_joined_iv with a value' do
            conductor = Conductor.new instance, options

            expect(conductor).to receive(:encrypt_with_joined_iv).with(value).and_call_original
            conductor.encrypt value
          end
        end

        context 'given an iv in the options' do
          context 'given an iv is a symbol' do
            xit 'calls #write_iv with the iv' do
              raise 'An iv as a symbol causes Encryptor#setup_cipher to break when setting the iv'
              options[:iv] = :some_iv
              conductor = Conductor.new instance, options

              expect(conductor).to receive(:write_iv).with(options[:iv]).and_call_original
              conductor.encrypt value
            end
          end

          it 'calls #write with the encrypted_value' do
            conductor = Conductor.new instance, options

            expect(conductor).to receive(:write).and_call_original
            conductor.encrypt value
          end
        end
      end

      describe '#encrypt_with_joined_iv' do

        it 'calls #write with the joined iv and encrypted value' do
          options = {encryptor: HipaaCrypt::Encryptor, attribute: 'encrypted_foo'}
          conductor = Conductor.new instance, options

          expect(conductor).to receive(:write).with(an_instance_of String).and_call_original
          conductor.encrypt_with_joined_iv value
        end
      end

      describe '#decrypt' do

        let(:options) { {encryptor: HipaaCrypt::Encryptor, attribute: 'encrypted_foo'} }

        context 'given a joined iv' do
          let(:options) { {encryptor: HipaaCrypt::Encryptor, attribute: 'encrypted_foo'} }
          let(:conductor) { Conductor.new instance, options }
          before { conductor.encrypt value }

          it 'calls #decrypt_with_joined_iv' do
            expect(conductor).to receive(:decrypt_with_joined_iv).and_call_original
            conductor.decrypt
          end
        end

        context 'given an iv in the options' do
          it 'decrypts the encrypted value with the current encryptor' do
            options[:iv] = SecureRandom.base64 44
            conductor = Conductor.new instance, options
            conductor.encrypt value

            expect_any_instance_of(HipaaCrypt::Encryptor).to receive(:decrypt).and_call_original
            conductor.decrypt
          end
        end
      end

      describe '#read' do
        it 'returns the value of the encrypted attribute' do
          options = {encryptor: HipaaCrypt::Encryptor, attribute: 'encrypted_foo'}
          instance.encrypted_foo = 'some_encrypted_value'
          conductor = Conductor.new instance, options

          expect(conductor.read).to eq 'some_encrypted_value'
        end
      end

      describe '#decrypt_with_joined_iv' do
        it 'decrypts the encrypted value' do
          options = {encryptor: HipaaCrypt::Encryptor, attribute: 'encrypted_foo'}
          conductor = Conductor.new instance, options
          conductor.encrypt value

          expect_any_instance_of(HipaaCrypt::Encryptor).to receive(:decrypt).and_call_original
          conductor.send :decrypt_with_joined_iv
        end
      end

      describe '#write' do
        it 'writes the value to the encrypted attribute' do
          options = {encryptor: HipaaCrypt::Encryptor, attribute: 'encrypted_foo'}
          conductor = Conductor.new instance, options

          expect(conductor.instance).to receive(:encrypted_foo=).with value
          conductor.send :write, value
        end
      end

      describe '#write_iv' do
        # TODO
      end

      describe '#convert_options' do
        let(:conductor) { Conductor.new instance, {} }

        context 'given a hash' do
          it 'calls #convert_options_hash' do
            options = {}

            expect(conductor).to receive(:convert_options_hash).with(options).and_call_original
            conductor.send :convert_options, options
          end
        end

        context 'given an array' do
          it 'calls #convert_options_array' do
            options = []

            expect(conductor).to receive(:convert_options_array).with(options).and_call_original
            conductor.send :convert_options, options
          end
        end

        context 'given a symbol' do
          it 'calls #convert_options_symbol' do
            options = :foo

            expect(conductor).to receive(:convert_options_symbol).with(options).and_call_original
            conductor.send :convert_options, options
          end
        end

        context 'given a proc' do
          it 'calls #convert_options_proc' do
            options = Proc.new {}

            expect(conductor).to receive(:convert_options_proc).with(options).and_call_original
            conductor.send :convert_options, options
          end
        end

        it 'calls #convert_options_value' do
          options = ""

          expect(conductor).to receive(:convert_options_value).with(options).and_call_original
          conductor.send :convert_options, options
        end
      end

      describe '#convert_options_hash' do
        let(:conductor) { Conductor.new instance, {} }

        it 'normalizes the options hash' do
          options = {key1: [:value1], key2: "value2", key1: '1'}
          expect(conductor.send :convert_options_hash, options).to eq options
        end
      end

      describe '#convert_options_array' do
        let(:conductor) { Conductor.new instance, {} }

        it 'returns an array of the converted options' do
          options = [{key1: :value1}, [2, 3], "value"]
          expect(conductor.send :convert_options_array, options).to eq options
        end
      end

      describe '#convert_options_symbol' do
        let(:conductor) { Conductor.new instance, {} }

        context 'when the option given is not an instance method' do
          it 'calls #convert_options_array' do
            options = :some_value

            expect(conductor).to receive(:convert_options_value).with(options).and_call_original
            conductor.send :convert_options_symbol, options
          end
        end

        context 'when the option given is an instance method' do
          it 'calls the instance method' do
            options = :encrypted_foo

            expect(instance).to receive(:encrypted_foo).and_call_original
            conductor.send :convert_options_symbol, options
          end
        end
      end

      describe '#convert_options_proc' do
        let(:conductor) { Conductor.new instance, {} }

        context 'given the proc does not take arguments' do
          it 'calls #instance_evalon the instance' do
            options = Proc.new {}
            expect(instance).to receive(:instance_eval).and_call_original
            conductor.send :convert_options_proc, options
          end
        end

        context 'given the proc takes arguments' do
          it 'calls the instance on the proc' do
            options = Proc.new {|n| "Hello #{n}"}
            expect(options).to receive(:call).with(instance).and_call_original
            conductor.send :convert_options_proc, options
          end
        end
      end

    end
  end
end