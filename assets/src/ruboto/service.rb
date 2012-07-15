require 'ruboto/base'
require 'ruboto/package'

#######################################################
#
# ruboto/service.rb
#
# Basic service set up and callback configuration.
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
  
    def start_ruboto_service(global_variable_name = '$service', klass=RubotoService, &block)
      $context_init_block = block
      $new_context_global = global_variable_name
  
      if @initialized or (self == $service) or ($service == nil) # FIx mix between activity and service
        self.startService Java::android.content.Intent.new(self, klass.java_class)
      else
        initialize_ruboto
        on_create
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
# Leave for legacy Service Subclass Setup
#

module Ruboto
  module Service
  end
end

#
# Basic Service Setup
#

def ruboto_configure_service(klass)
  klass.class_eval do
    include Ruboto::Service
    
    def on_create
    end
  end
end

ruboto_import "org.ruboto.RubotoService"
ruboto_configure_service(RubotoService)

