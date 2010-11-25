# AR spec
require 'rubygems'
Dir["#{File.dirname(__FILE__)}/../tasks/*.rake"].sort.each { |ext| load ext }

if ENV['VERSION_3']
  gem 'activerecord', [ '>= 3.0.0'], :require => 'active_record'
else
  gem 'activerecord', [ '>= 2.3.4', '<= 2.3.10' ], :require => 'active_record'
end
require File.join( File.dirname(__FILE__), 'spec_helper')
require File.join( File.dirname(__FILE__), '..', 'lib', 'orms', 'active_record')
require 'connection'

# Load required Modules
ActiveRecord::Base.configurations.each do |env, conf|
    require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'yaml', 'query_builder', 'sql', conf['adapter']))
end

def schema_already_exists?
  ActiveRecord::Base.connection.table_exists?('jobs')
end

unless ActiveRecord::Base.connected?
  begin
    ActiveRecord::Base.connection
  rescue
    Rake::Task["#{$ADAPTER}:build_databases"].invoke
  end
end

unless schema_already_exists?
  load(File.join( File.dirname(__FILE__), 'schema.rb'))
end
