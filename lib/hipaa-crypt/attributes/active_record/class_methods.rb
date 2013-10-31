module HipaaCrypt
  module Attributes
    module ActiveRecord
      module ClassMethods

        private

        def relation(*args)
          super(*args).tap do |relation|
            relation.extend RelationAdditions
          end
        end

        def prefix_unencrypted_methods_for_attr(*args)
        end

        def setter_defined?(attr)
          column_names.include? attr.to_s
        end

        if ::ActiveRecord::VERSION::STRING < '4.0.0'

          def all_attributes_exists?(attribute_names)
            attr_names_with_enc = attribute_names.map do |attr|
              if (encryptor = encryptor_for attr)
                prefix = encryptor.options.raw_value(:prefix)
                [prefix, attr].join
              else
                attr
              end
            end
            super(attr_names_with_enc)
          end

        end

      end
    end
  end
end
