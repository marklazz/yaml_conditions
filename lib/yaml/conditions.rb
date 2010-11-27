module Yaml
  module Conditions
    extend self
    ParseObjectFromYaml = /\!ruby\/\w+\:([^\s]+)/

    VERSION = '0.0.1'
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
