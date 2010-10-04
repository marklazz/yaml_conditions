require 'rubygems'
require File.join(File.dirname(__FILE__), 'yaml', 'conditions')

if defined?(ActiveRecord)
  require File.join(File.dirname(__FILE__), 'orms', 'active_record')
elsif defined?(DataMapper)
  require File.join(File.dirname(__FILE__), 'orms', 'datamapper')
end
