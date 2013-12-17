require 'logger'
require 'navigable_hash'

module HipaaCrypt
  class Configuration < NavigableHash

    def initialize(*args)
      super(*args)
    end

  end
end