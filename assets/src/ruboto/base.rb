#######################################################
#
# ruboto/base.rb
#
# Code shared by other ruboto components.
#
#######################################################

require 'java'

class Class
  def method_added(name)
    # Create camel case alias of snake case "on_" methods
    name = name.to_s
    alias_method(name.gsub(/_[a-z]/){|i| i[1].upcase}, name) if name[0..2] == "on_"
  end
end

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

java_import 'android.R'
AndroidIds = JavaUtilities.get_proxy_class('android.R$id')

module Ruboto
  CLASS_NAME_KEY = org.ruboto.ScriptInfo::CLASS_NAME_KEY
  SCRIPT_NAME_KEY = org.ruboto.ScriptInfo::SCRIPT_NAME_KEY
  THEME_KEY = org.ruboto.RubotoActivity::THEME_KEY
end
