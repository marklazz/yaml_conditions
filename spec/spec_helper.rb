require File.join( File.dirname(__FILE__), '..', 'lib', 'yaml_conditions')
if ENV['VERSION_3']
  gem 'activesupport', [ '>= 3.0.0'], :require => 'active_support'
else
  gem 'activesupport', [ '>= 2.3.4', '<= 2.3.10' ], :require => 'active_support'
end

module Kernel
  def silence_warnings
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end

  def without_output
    orig_stdout = $stderr
    # redirect stdout to /dev/null
    $stderr = File.new('/dev/null', 'w')
    yield
    # restore stdout
    $stderr = orig_stdout
  end
end
