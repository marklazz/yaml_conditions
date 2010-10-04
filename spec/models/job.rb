require File.expand_path(File.join(File.dirname(__FILE__), 'priority'))

class Job < ActiveRecord::Base
  has_many :priorities
end
