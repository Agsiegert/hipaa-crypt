require 'logger'
require 'navigable_hash'

module HipaaCrypt
  class Configuration < NavigableHash

    def initialize(*args)
      super(*args)
    end

    def key
      self['key']
    end

    def key=(key)
      self['key'] = key
    end

    def extractable_options?
      instance_of?(HipaaCrypt::Configuration)
    end

  end
end