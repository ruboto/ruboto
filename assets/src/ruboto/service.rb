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
    def start_ruboto_service(global_variable_name='$service', klass=RubotoService, options={}, &block)
      # FIXME(uwe): Translate old positional signature to new options-based signature.
      # FIXME(uwe): Remove when we stop supporting Ruboto 0.8.0 or older.
      if options.nil?
        if global_variable_name.is_a?(Hash)
          options = global_variable_name
        else
          options = {}
        end
        global_variable_name = nil
      end

      class_name = options[:class_name] || "#{klass.name.split('::').last}_#{source_descriptor(block)[0].split("/").last.gsub(/[.-]+/, '_')}_#{source_descriptor(block)[1]}"
      if !Object.const_defined?(class_name)
        Object.const_set(class_name, Class.new(&block))
      else
        Object.const_get(class_name).class_eval(&block) if block_given?
      end
      b = Java::android.os.Bundle.new
      b.putString("ClassName", class_name)
      b.putString("Script", options[:script]) if options[:script]
      i = android.content.Intent.new
      i.setClass self, klass.java_class
      i.putExtra("Ruboto Config", b)
      self.startService i
      self
    end
  end
end

Context.class_eval do
  include Ruboto::Context
end
