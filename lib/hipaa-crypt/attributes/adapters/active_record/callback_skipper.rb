module HipaaCrypt
  module Attributes
    module Adapters
      module ActiveRecord
        module CallbackSkipper

          # Invoke a save without executing any callbacks.
          def save_without_callbacks
            !changed? || 1 == self.class.unscoped.where(self.class.primary_key => id).update_all(get_changed_attributes)
          rescue => e
            HipaaCrypt.logger.error "Re-Encrypt Error => #{e.class}: #{e.message}"
            false
          end

          def get_changed_attributes
            changed.reduce({}) do |hash, attr|
              hash.merge attr => read_attribute(attr)
            end
          end

        end
      end
    end
  end
end
