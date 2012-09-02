require 'ruboto/base'
require 'ruboto/package'

#######################################################
#
# ruboto/activity.rb
#
# Basic activity set up and callback configuration.
#
#######################################################

#
# Context
#

module Ruboto
  module Context
    def initialize_ruboto()
      eval("#{$new_context_global} = self")
      $new_context_global = nil

      instance_eval &$context_init_block if $context_init_block
      $context_init_block = nil
      setup_ruboto_callbacks 

      @initialized = true
      self
    end
  
    def start_ruboto_dialog(remote_variable, theme=Java::android.R.style::Theme_Dialog, &block)
      ruboto_import "org.ruboto.RubotoDialog"
      start_ruboto_activity(remote_variable, RubotoDialog, theme, &block)
    end
  
    def start_ruboto_activity(global_variable_name = '$activity', klass=RubotoActivity, theme=nil, options = nil, &block)
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

      # FIXME(uwe): Used for block-based definition of main activity.
      # FIXME(uwe): Remove when we stop supporting Ruboto 0.8.0 or older.
      puts "start_ruboto_activity self: #{self.inspect}"
      if @ruboto_java_class and not @ruboto_java_class_initialized
        @ruboto_java_class_initialized = true
        puts "Block based main activity definition"
        instance_eval &block if block
        setup_ruboto_callbacks
        on_create nil
      else
        puts "Class based main activity definition"
        class_name = options[:class_name] || "#{klass.name.split('::').last}_#{source_descriptor(block)[0].split("/").last.gsub(/[.]+/, '_')}_#{source_descriptor(block)[1]}"
        if !Object.const_defined?(class_name)
          Object.const_set(class_name, Class.new(&block))
        else
          Object.const_get(class_name).class_eval(&block)
        end
        b = Java::android.os.Bundle.new
        b.putInt("Theme", theme) if theme
        b.putString("ClassName", class_name)
        i = android.content.Intent.new
        i.setClass self, klass.java_class
        i.putExtra("RubotoActivity Config", b)
        startActivity i
      end
      self
    end

    private

    def source_descriptor(proc)
      if md = /^#<Proc:0x[0-9A-Fa-f]+@(.+):(\d+)(?: \(lambda\))?>$/.match(proc.inspect)
        filename, line = md.captures
        return filename, line.to_i
      end
    end

  end

end

java_import "android.content.Context"
Context.class_eval do
  include Ruboto::Context
end

#
# Basic Activity Setup
#

module Ruboto
  module Activity
    def method_missing(method, *args, &block)
      return @ruboto_java_instance.send(method, *args, &block) if @ruboto_java_instance && @ruboto_java_instance.respond_to?(method)
      super
    end
  end
end

def ruboto_configure_activity(klass)
  klass.class_eval do
    include Ruboto::Activity
  end
end

java_import "android.app.Activity"
ruboto_import "org.ruboto.RubotoActivity"
ruboto_configure_activity(RubotoActivity)

