require 'ruboto/base'

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
  
    def start_ruboto_activity(global_variable_name, klass=RubotoActivity, theme=nil, &block)
      $context_init_block = block
      $new_context_global = global_variable_name
  
      if @initialized or (self == $activity && !$activity.kind_of?(RubotoActivity))
        b = Java::android.os.Bundle.new
        b.putInt("Theme", theme) if theme
  
        i = Java::android.content.Intent.new
        i.setClass self, klass.java_class
        i.putExtra("RubotoActivity Config", b)
  
        self.startActivity i
      else
        initialize_ruboto
        on_create nil
      end
  
      self
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
  end
end
  
def ruboto_configure_activity(klass)
  klass.class_eval do
    include Ruboto::Activity
    
    # Can't be moved into the module
    def on_create(bundle)
    end
  end
end

java_import "android.app.Activity"
ruboto_import "org.ruboto.RubotoActivity"
ruboto_configure_activity(RubotoActivity)

