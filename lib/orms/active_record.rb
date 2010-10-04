require 'active_record'

if ::ActiveRecord::VERSION::MAJOR == 2
  require File.join(File.dirname(__FILE__), 'active_record', 'version_2')
elsif ::ActiveRecord::VERSION::MAJOR == 3
  require File.join(File.dirname(__FILE__), 'active_record', 'version_3')
end
