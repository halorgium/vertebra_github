if dir = ENV["VERTEBRA_DIR"]
  $:.unshift dir
end
require File.dirname(__FILE__) + '/../lib/herault'
