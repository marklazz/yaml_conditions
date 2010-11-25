require File.join( File.dirname(__FILE__), '..', 'lib', 'yaml_conditions')
if ENV['VERSION_3']
  gem 'activesupport', [ '>= 3.0.0'], :require => 'active_support'
else
  gem 'activesupport', [ '>= 2.3.4', '<= 2.3.10' ], :require => 'active_support'
end

def with_warnings(flag)
  old_verbose, $VERBOSE = $VERBOSE, flag
  yield
  ensure
    $VERBOSE = old_verbose
end
