$package = JavaUtilities.get_package_module_dot_format($package_name)
R = $package.R

class R
  def self.attr
    JavaUtilities.get_proxy_class("#{$package_name}.R$attr")
  end
end

# FIXME(uwe):  DEPRECATED(2014-07-29):  Use R and R.id instead.
module Ruboto
  R = ::R
  begin
    Id = R.id
  rescue NameError
    Java::android.util.Log.d 'RUBOTO', 'no R$id'
  end
end
# EMXIF
