require 'rake/clean'
require 'fileutils'
require 'date'
require 'spec/rake/spectask'
require 'mocha'
require 'hanna/rdoctask'

# Removes spec task defiened in dependency gems
module Rake
  def self.remove_task(task_name)
    Rake.application.instance_variable_get('@tasks').delete(task_name.to_s)
  end
end
Rake.remove_task 'spec'

def source_version
  line = File.read('lib/yaml_conitions.rb')[/^\s*VERSION = .*/]
  line.match(/.*VERSION = '(.*)'/)[1]
end

# SPECS ===============================================================

desc 'Run mysql, sqlite, and postgresql tests by default'
task :default => :spec

desc 'Run mysql, sqlite, and postgresql tests'
task :spec do
  tasks = defined?(JRUBY_VERSION) ?
    %w(spec_jdbcmysql spec_jdbcpostgresql) :
    %w(spec_mysql spec_postgresql)
  run_without_aborting(*tasks)
end

def run_without_aborting(*tasks)
  errors = []

  tasks.each do |task|
    begin
      Rake::Task[task].invoke
    rescue Exception
      errors << task
    end
  end

  abort "Errors running #{errors.join(', ')}" if errors.any?
end

task :default => :spec

for adapter in %w( mysql postgresql )

  Spec::Rake::SpecTask.new("spec_#{adapter}") do |t|
    t.spec_opts = ['--color']
    t.rcov = false
    if adapter =~ /jdbc/
      t.libs << "spec/connections/jdbc_#{adapter}"
    else
      t.libs << "spec/connections/#{adapter}"
    end
      t.spec_files = FileList[ 'spec/cases/**/*_spec.rb', 'spec/lib/**/*_spec.rb' ]
    end

  namespace adapter do
    task "spec_#{adapter}" => [ "rebuild_#{adapter}_databases" ]
    task :spec => "spec_#{adapter}"
  end
end

# DB ==================================================================
# CREATE USER yaml_conditions
MYSQL_DB_USER = 'yaml_conditions'

namespace :mysql do
  desc 'Build the MySQL test databases'
  task :build_databases do
    %x( echo "create DATABASE yaml_conditions_db DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci " | mysql --user=#{MYSQL_DB_USER})
  end

  desc 'Drop the MySQL test databases'
  task :drop_databases do
    %x( mysqladmin -u#{MYSQL_DB_USER} -f drop yaml_conditions_db )
  end

  desc 'Rebuild the MySQL test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]
end

task :build_mysql_databases => 'mysql:build_databases'
task :drop_mysql_databases => 'mysql:drop_databases'
task :rebuild_mysql_databases => 'mysql:rebuild_databases'


namespace :postgresql do
  desc 'Build the PostgreSQL test databases'
  task :build_databases do
    %x( createdb -E UTF8 yaml_conditions_db )
  end

  desc 'Drop the PostgreSQL test databases'
  task :drop_databases do
    %x( dropdb yaml_conditions_db )
  end

  desc 'Rebuild the PostgreSQL test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]
end

task :build_postgresql_databases => 'postgresql:build_databases'
task :drop_postgresql_databases => 'postgresql:drop_databases'
task :rebuild_postgresql_databases => 'postgresql:rebuild_databases'

# Rcov ================================================================
namespace :spec do
  desc 'Mesures test coverage'
  task :coverage do
    rm_f "coverage"
    rcov = "rcov --text-summary -Ilib"
    system("#{rcov} --no-html --no-color spec/lib/*_spec.rb")
  end
end

# Website =============================================================
# Building docs requires HAML and the hanna gem:
#   gem install mislav-hanna --source=http://gems.github.com

desc 'Generate RDoc under doc/api'
task 'doc'     => ['doc:api']

task 'doc:api' => ['doc/api/index.html']

file 'doc/api/index.html' => FileList['lib/**/*.rb','README.rdoc'] do |f|
  require 'rbconfig'
  hanna = RbConfig::CONFIG['ruby_install_name'].sub('ruby', 'hanna')
  rb_files = f.prerequisites
  sh((<<-end).gsub(/\s+/, ' '))
    #{hanna}
      --charset utf8
      --fmt html
      --inline-source
      --line-numbers
      --main README.rdoc
      --op doc/api
      --title 'RTT API Documentation'
      #{rb_files.join(' ')}
  end
end
CLEAN.include 'doc/api'
