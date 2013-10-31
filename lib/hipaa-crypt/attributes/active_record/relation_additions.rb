module HipaaCrypt
  module Attributes
    module ActiveRecord
      module RelationAdditions

        def where(opts, *rest)
          return super(opts, *rest) unless opts.is_a? Hash
          encrypted_opts = opts.reduce({}) do |hash, (key, value)|
            hash[key] = opts.delete(key) if attribute_encrypted? key
            hash
          end
          query          = super(opts, *rest)
          encrypted_opts.present? ? query.encrypted_where(encrypted_opts) : query
        end

        protected

        def encrypted_where(opts)
          grouped_opts = opts.group_by do |attr, v|
            opts = encryptor_for(attr).options
            opts.raw_value(:iv).is_a?(String) && opts.raw_value(:key).is_a?(String) ? :static : :dynamic
          end
          static_key_iv_where(grouped_opts[:static]).load_and_decrypt_where(grouped_opts[:dynamic])
        end

        def static_key_iv_where(opts)
          return self unless opts.present?
          opts.reduce(self) do |arel, (attr, value)|
            encryptor       = encryptor_for(attr)
            encrypted_value = encryptor.encrypt(value)
            enc_attr        = [encryptor.options.raw_value(:prefix), attr].join
            arel.where(enc_attr => encrypted_value)
          end
        end

        def load_and_decrypt_where(opts)
          return self unless opts.present?
          instances = select do |instance|
            instance.matches_conditions opts
          end
          where primary_key => instances.map(&primary_key.to_sym)
        end

      end
    end
  end
end
