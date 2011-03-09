module Ruboto
  # Enable ObjectSpace if running in JRuby, for the "main" lib
  def self.enable_objectspace
    require 'jruby'
    JRuby.objectspace = true
  rescue LoadError
  end
end