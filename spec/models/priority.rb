require File.expand_path(File.join(File.dirname(__FILE__), 'job'))

class Priority < ActiveRecord::Base
  belongs_to :job
end
