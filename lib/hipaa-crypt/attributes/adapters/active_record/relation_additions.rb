module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord
        module RelationAdditions

          module Extender
            def relation(*args)
              super(*args).tap do |relation|
                relation.extend RelationAdditions
              end
            end
          end

          # Extends ActiveRecord's #where to support encrypted fields.
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
              opts = encrypted_options_for(attr)
              opts[:iv].is_a?(String) && opts[:key].is_a?(String) ? :static : :dynamic
            end
            static_key_iv_where(grouped_opts[:static]).load_and_decrypt_where(grouped_opts[:dynamic])
          end

          def static_key_iv_where(opts)
            return self unless opts.present?
            opts.reduce(self) do |arel, (attr, value)|
              enc_attr        = encrypted_options_for(attr)[:attribute]
              encrypted_value = new(attr => value).conductor_for(attr).read
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
end