require 'ruboto/base'
require 'ruboto/package'

#######################################################
#
# ruboto/service.rb
#
# Basic service set up.
#
#######################################################

java_import "android.content.Context"
java_import "org.ruboto.RubotoService"

module Ruboto
  module Context
    def start_ruboto_service(global_variable_name = '$service', klass=RubotoService, &block)
      class_name = options[:class_name] || "#{klass.name.split('::').last}_#{source_descriptor(block)[0].split("/").last.gsub(/[.-]+/, '_')}_#{source_descriptor(block)[1]}"
      if !Object.const_defined?(class_name)
        Object.const_set(class_name, Class.new(&block))
      else
        Object.const_get(class_name).class_eval(&block) if block_given?
      end
      b = Java::android.os.Bundle.new
      b.putInt("Theme", theme) if theme
      b.putString("ClassName", class_name)
      i = android.content.Intent.new
      i.setClass self, klass.java_class
      i.putExtra("RubotoActivity Config", b)
      self.startService Java::android.content.Intent.new(self, klass.java_class)
      self
    end
  end
end

Context.class_eval do
  include Ruboto::Context
end
