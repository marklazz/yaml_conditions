module Yaml
  module Conditions
    extend self
    ParseObjectFromYaml = /\!ruby\/\w+\:([^\s]+)/

    VERSION = '0.0.1'
  end
end
