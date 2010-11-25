module Delayed
  class PerformableMethod < Struct.new(:object, :method, :args)
  end
end
