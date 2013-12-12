module HipaaCrypt
  class Error < StandardError

    # Copy an error to the HipaaCrypt namespace.
    def self.copy_and_raise(error)
      name = error.class.name.split('::').join
      raise const_get(name, false), error.message
    end

    private

    def self.const_missing(name)
      const_set name, Class.new(Error)
    end

  end
end