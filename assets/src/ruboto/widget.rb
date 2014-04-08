require 'ruboto/base'
require 'ruboto/activity'

#######################################################
#
# ruboto/widget.rb
#
# Import widgets and set up methods on activity to 
# create and initialize. You do not need this if
# you want to call the Android methods directly.
#
#######################################################

#
# Prepare View
#

java_import 'android.view.View'

def invoke_with_converted_arguments(target, method_name, values)
  converted_values = [*values].map { |i| @@convert_constants[i] || i }
  scaled_values = converted_values.map.with_index do |v, i|
    v.is_a?(Integer) && v >= 0x80000000 && v <= 0xFFFFFFFF ?
        v.to_i - 0x100000000 : v
  end
  target.send(method_name, *scaled_values)
end

View.class_eval do
  @@convert_constants ||= {}

  def self.add_constant_conversion(from, to)
    @@convert_constants[from] = to
  end

  def self.convert_constant(from)
    return from unless from.is_a?(Symbol)
    @@convert_constants[from] or raise "Symbol #{from.inspect} doesn't have a corresponding View constant #{from.to_s.upcase}"
  end

  def self.setup_constant_conversion
    (self.constants - self.superclass.constants).each do |i|
      View.add_constant_conversion i.downcase.to_sym, self.const_get(i)
    end
  end

  def configure(context, params = {})
    if width = params.delete(:width)
      getLayoutParams.width = View.convert_constant(width)
      puts "\nDEPRECATION: The ':width' option is deprecated.  Use :layout => {:width => XX} instead."
    end

    if height = params.delete(:height)
      getLayoutParams.height = View.convert_constant(height)
      puts "\nDEPRECATION: The ':height' option is deprecated.  Use :height => {:width => XX} instead."
    end

    if margins = params.delete(:margins)
      getLayoutParams.set_margins(*margins)
      puts "\nDEPRECATION: The ':margins' option is deprecated.  Use :layout => {:margins => XX} instead."
    end

    if layout = params.delete(:layout)
      lp = getLayoutParams
      layout.each do |k, v|
        method_name = k.to_s
        if lp.respond_to?("#{k}=")
          method_name = "#{k}="
        elsif method_name.include?("_")
          method_name = method_name.gsub(/_([a-z])/){$1.upcase}
          method_name = "#{method_name}=" if lp.respond_to?("#{method_name}=")
        end
          
        invoke_with_converted_arguments(lp, method_name, v)
      end
    end

    params.each do |k, v|
      setter_method = "set#{k.to_s.gsub(/(^|_)([a-z])/) { $2.upcase }}"
      assign_method = "#{k}="
      method_name = self.respond_to?(assign_method) ? assign_method :
          (self.respond_to?(setter_method) ? setter_method : k)
      invoke_with_converted_arguments(self, method_name, v)
    end
  end
end

#
# Load ViewGroup constants
#

java_import 'android.view.ViewGroup'
ViewGroup::LayoutParams.constants.each do |i|
  View.add_constant_conversion i.downcase.to_sym, ViewGroup::LayoutParams.const_get(i)
end

#
# Load Gravity constants
#

java_import 'android.view.Gravity'
Gravity.constants.each do |i|
  View.add_constant_conversion i.downcase.to_sym, Gravity.const_get(i)
end

#
# RubotoActivity View Generation
#

def ruboto_import_widgets(*widgets)
  widgets.each { |i| ruboto_import_widget i }
end

def ruboto_import_widget(class_name, package_name='android.widget')
  if class_name.is_a?(String) or class_name.is_a?(Symbol)
    klass = java_import("#{package_name}.#{class_name}") || eval("Java::#{package_name}.#{class_name}")
  else
    klass = class_name
    java_import klass
    class_name = klass.java_class.name.split('.')[-1]
  end

  return unless klass

  method_str = "
     def #{(class_name.to_s.gsub(/([A-Z])/) { '_' + $1.downcase })[1..-1]}(params={})
        if force_style = params.delete(:default_style)
          rv = #{class_name}.new(self, nil, force_style)
        elsif api_key = params.delete(:apiKey)
          rv = #{class_name}.new(self, api_key)
        else
          rv = #{class_name}.new(self)
        end

        if parent = (params.delete(:parent) || @view_parent)
          parent.addView(rv, (params.delete(:parent_index) || parent.child_count))
        end

        rv.configure self, params

        return rv unless block_given?

        old_view_parent, @view_parent = @view_parent, rv
        yield
        @view_parent = old_view_parent

        rv
     end
   "
  RubotoActivity.class_eval method_str

  # FIXME(uwe): Remove condition when we stop support for api level < 11
  if android.os.Build::VERSION::SDK_INT >= 11
    android.app.Fragment.class_eval method_str.gsub('self', 'activity')
  end
  # EMXIF

  setup_list_view if class_name == :ListView
  setup_spinner if class_name == :Spinner
  setup_button if class_name == :Button
  setup_image_button if class_name == :ImageButton
  setup_linear_layout if class_name == :LinearLayout
  setup_relative_layout if class_name == :RelativeLayout

  klass
end

#
# Special widget setup
#

def setup_linear_layout
  Java::android.widget.LinearLayout.setup_constant_conversion
end

def setup_relative_layout
  Java::android.widget.RelativeLayout.setup_constant_conversion
end

def setup_button
  # legacy
end

def setup_image_button
  # legacy
end

def setup_list_view
  android.widget.ListView.__persistent__ = true
  android.widget.ListView.class_eval do
    def configure(context, params = {})
      if (list = params.delete(:list))
        item_layout = params.delete(:item_layout) || R::layout::simple_list_item_1
        params[:adapter] = android.widget.ArrayAdapter.new(context, item_layout, list)
      end
      super(context, params)
    end

    def reload_list(list)
      @adapter_list.clear
      @adapter_list.addAll(list)
      adapter.notifyDataSetChanged
      invalidate
    end
  end
end

def setup_spinner
  android.widget.Spinner.__persistent__ = true
  android.widget.Spinner.class_eval do
    def configure(context, params = {})
      if (list = params.delete(:list))
        item_layout = params.delete(:item_layout)
        params[:adapter] = android.widget.ArrayAdapter.new(context, item_layout || R::layout::simple_spinner_item, list)
        dropdown_layout = params.delete(:dropdown_layout)
        params[:adapter].setDropDownViewResource(dropdown_layout) if dropdown_layout
      end
      super(context, params)
    end

    def reload_list(list)
      @adapter.clear
      @adapter.addAll(list)
      @adapter.notifyDataSetChanged
      invalidate
    end
  end
end

