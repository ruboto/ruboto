#######################################################
#
# ruboto/preference.rb
#
# Basic set up for preferences (activity and widgets).
#
#######################################################

require 'ruboto/activity'

java_import "android.preference.PreferenceScreen"
java_import "android.preference.Preference"
java_import "org.ruboto.RubotoPreferenceActivity"
ruboto_configure_activity(RubotoPreferenceActivity)

RubotoPreferenceActivity.class_eval do
    def preference_screen(params={})
      rv = self.getPreferenceManager.createPreferenceScreen(self)
      parent = params.delete(:parent) || @parent
      rv.configure self, params
      parent.addPreference(rv) if parent

      if block_given?
        old_parent, @parent = @parent, rv
        yield
        @parent = old_parent
      end
      rv
    end
end

Preference.class_eval do
    def configure(context, params = {})
      params.each do |k, v|
        if v.is_a?(Array)
          self.send("set#{k.to_s.gsub(/(^|_)([a-z])/) { $2.upcase }}", *v)
        else
          self.send("set#{k.to_s.gsub(/(^|_)([a-z])/) { $2.upcase }}", v)
        end
      end
    end
end

#
# RubotoPreferenceActivity Preference Generation
#

def ruboto_import_preferences(*preferences)
  preferences.each { |i| ruboto_import_preference i }
end

def ruboto_import_preference(class_name, package_name="android.preference")
  klass = java_import("#{package_name}.#{class_name}") || eval("Java::#{package_name}.#{class_name}")
  return unless klass

  RubotoPreferenceActivity.class_eval "
     def #{(class_name.to_s.gsub(/([A-Z])/) { '_' + $1.downcase })[1..-1]}(params={})
        rv = #{class_name}.new self
        parent = params.delete(:parent) || @parent
        rv.configure self, params
        parent.addPreference(rv) if parent
      
        if block_given?
          old_parent, @parent = @parent, rv
          yield
          @parent = old_parent
        end
        rv
     end
   "
end

