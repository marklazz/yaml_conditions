require 'rubygems'
require 'echoe'

# PACKAGING ============================================================

Echoe.new('yaml_conditions', '0.0.0.1') do |p|
  p.description = ''
  p.url = 'http://github.com/marklazz/yaml_conditions'
  p.author = 'Marcelo Giorgi'
  p.email = 'marklazz.uy@gmail.com'
  p.ignore_pattern = [ 'tmp/*', 'script/*', '*.sh' ]
  p.runtime_dependencies = []
  p.development_dependencies = [ 'spec' ]
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
