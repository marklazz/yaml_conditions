module Yaml
  module Conditions
    extend self

    VERSION = '0.0.0.4'
  end

  class NotSerializedField

    def initialize(value)
      @value = value
    end

    def ==(v)
      @value == v
    end
  end
end
