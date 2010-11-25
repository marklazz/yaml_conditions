require 'active_record'
require(File.join(File.dirname(__FILE__), 'active_record', 'version2', 'delayed_job'))

if ::ActiveRecord::VERSION::MAJOR == 2
  require File.join(File.dirname(__FILE__), 'active_record', 'version_2')
elsif ::ActiveRecord::VERSION::MAJOR == 3
  require File.join(File.dirname(__FILE__), 'active_record', 'version_3')
end
