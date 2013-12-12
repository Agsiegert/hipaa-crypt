module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord
        module CallbackSkipper

          # Invoke a save without executing any callbacks.
          def save_without_callbacks
            changed_attrs = changed.reduce({}) do |hash, attr|
              hash.merge attr => read_attribute(attr)
            end
            changed_attrs.blank? || 1 == self.class.unscoped.where(self.class.primary_key => id).update_all(changed_attrs)
          rescue => e
            HipaaCrypt.logger.error "Re-Encrypt Error => #{e.class}: #{e.message}"
            false
          end

        end
      end
    end
  end
end
