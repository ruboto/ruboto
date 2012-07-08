#######################################################
#
# ruboto/base.rb
#
# Code shared by other ruboto components.
#
#######################################################

# Only used needed for ruboto-core apps
require 'ruboto/version'
$RUBOTO_VERSION = 10

def confirm_ruboto_version(required_version, exact=true)
  raise "requires $RUBOTO_VERSION=#{required_version} or greater, current version #{$RUBOTO_VERSION}" if $RUBOTO_VERSION < required_version and not exact
  raise "requires $RUBOTO_VERSION=#{required_version}, current version #{$RUBOTO_VERSION}" if $RUBOTO_VERSION != required_version and exact
end

require 'java'

# Create convenience method for top-level android package so we do not need to prefix with 'Java::'.
module Kernel
  def android
    JavaUtilities.get_package_module_dot_format('android')
  end
end

java_import "android.R"
AndroidIds = JavaUtilities.get_proxy_class("android.R$id")

#
# Callbacks
#

module Ruboto
  module CallbackClass
    def new_with_callbacks(*args, &block)
      new(*args).initialize_ruboto_callbacks(&block)
    end
  end
    
  module Callbacks
    def initialize_ruboto_callbacks &block
      instance_eval &block
      setup_ruboto_callbacks
      self
    end
    
    def ruboto_callback_methods 
      (singleton_methods - ["on_create", "on_receive"]).select{|i| self.class.constants.include?(i.to_s.sub(/^on_/, "CB_").upcase) || self.class.constants.include?("CB_#{i}".upcase)}
    end 

    def setup_ruboto_callbacks 
      ruboto_callback_methods.each do |i| 
        begin
          setCallbackProc((self.class.constants.include?(i.to_s.sub(/^on_/, "CB_").upcase) && self.class.const_get(i.to_s.sub(/^on_/, "CB_").upcase)) || (self.class.constants.include?("CB_#{i}".upcase) && self.class.const_get("CB_#{i}".upcase)), method(i))
        rescue
        end
      end 
    end 
  end
end

#
# Import a class and set it up for handlers
#

def ruboto_import(*package_classes)
  already_classes = package_classes.select{|i| not i.is_a?(String) and not i.is_a?(Symbol)}
  imported_classes = package_classes - already_classes

  unless imported_classes.empty?
    # TODO(uwe): The first part of this "if" is only needed for JRuby 1.6.x.  Simplify when we stop supporting JRuby 1.6.x
    if imported_classes.size == 1
      imported_classes = [*(java_import(*imported_classes) || eval("Java::#{imported_classes[0]}"))]
    else
      imported_classes = java_import(imported_classes)
    end
  end

  (already_classes + imported_classes).each do |package_class|
    package_class.class_eval do
      extend Ruboto::CallbackClass
      include Ruboto::Callbacks
    end
  end
end

