#######################################################
#
# ruboto/base.rb
#
# Code shared by other ruboto components.
#
#######################################################

require 'java'

# Create convenience method for top-level android package so we do not need to prefix with 'Java::'.
module Kernel
  def android
    JavaUtilities.get_package_module_dot_format('android')
  end

  alias :old_method_missing :method_missing
  def method_missing(method, *args, &block)
    return @ruboto_java_instance.send(method, *args, &block) if @ruboto_java_instance && @ruboto_java_instance.respond_to?(method)
    old_method_missing(method, *args, &block)
  end
end

java_import "android.R"
AndroidIds = JavaUtilities.get_proxy_class("android.R$id")
