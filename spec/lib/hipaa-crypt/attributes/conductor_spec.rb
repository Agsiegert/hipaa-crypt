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

        before do
          allow(HipaaCrypt).to receive(:config).and_return( NavigableHash.new do |c|
            c.key = SecureRandom.hex
            c.cipher = { name: :AES, key_length: 256, mode: :CBC }
          end
        )
        end

        let(:options) { {encryptor: HipaaCrypt::Encryptor, attribute: 'encrypted_foo'} }
        let(:value) {'foo'}

        context 'given a joined iv' do
          it 'calls #encrypt_with_joined_iv with a value' do
            conductor = Conductor.new instance, options

            expect(conductor).to receive(:encrypt_with_joined_iv).with(value).and_call_original
            conductor.encrypt value
          end
        end

        context 'given an iv in the options' do
          context 'given an iv is a symbol' do
            it 'calls #write_iv with the iv' do
              raise 'boom!!!'
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
    end
  end
end