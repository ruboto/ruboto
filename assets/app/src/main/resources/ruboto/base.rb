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
    Java::Android
  end

  alias :old_method_missing :method_missing
  def method_missing(method, *args, &block)
    if @ruboto_java_instance && @ruboto_java_instance.respond_to?(method)
      return @ruboto_java_instance.send(method, *args, &block)
    end
    old_method_missing(method, *args, &block)
  end
end

class Java::Android::R
  def self.attr
    JavaUtilities.get_proxy_class("android.R$attr")
  end
end

# FIXME(uwe):  DEPRECATED(2014-07-29):  Remove since we can access the value directly with "android.R.id", ie. "android.R.id.text1"
AndroidIds = android.R.id
# EMXIF

module Ruboto
  CLASS_NAME_KEY = org.ruboto.ScriptInfo::CLASS_NAME_KEY
  SCRIPT_NAME_KEY = org.ruboto.ScriptInfo::SCRIPT_NAME_KEY
  THEME_KEY = org.ruboto.RubotoActivity::THEME_KEY
end
