require 'rubygems'
require File.join(File.dirname(__FILE__), 'yaml', 'conditions')
require File.join(File.dirname(__FILE__), 'yaml', 'query_builder')

if defined?(ActiveRecord)
  require File.join(File.dirname(__FILE__), 'orms', 'active_record')

  # Load required Modules
  ActiveRecord::Base.configurations.each do |env, conf|
    require File.expand_path(File.join(File.dirname(__FILE__), 'yaml', 'query_builder', 'sql', conf['adapter']))
  end

elsif defined?(DataMapper)
  require File.join(File.dirname(__FILE__), 'orms', 'datamapper')
end
