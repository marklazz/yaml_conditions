# AR spec
require 'rubygems'
if ENV['VERSION_3']
  gem 'activerecord', [ '>= 3.0.0'], :require => 'active_record'
else
  gem 'activerecord', [ '>= 2.3.4', '<= 2.3.10' ], :require => 'active_record'
end
require File.join( File.dirname(__FILE__), 'spec_helper')
require File.join( File.dirname(__FILE__), '..', 'lib', 'orms', 'active_record')
require 'connection'

def schema_already_exists?
  ActiveRecord::Base.connection.table_exists?('jobs')
end

unless schema_already_exists?
  load(File.join( File.dirname(__FILE__), 'schema.rb'))
end
