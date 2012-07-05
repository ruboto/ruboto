$package_name = ($activity || $service).package_name
$package      = eval("Java::#{$package_name}")

module Ruboto
  java_import "#{$package_name}.R"
  begin
    Id = JavaUtilities.get_proxy_class("#{$package_name}.R$id")
  rescue NameError
    Java::android.util.Log.d "RUBOTO", "no R$id"
  end
end
