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

java_import "android.view.View"

View.class_eval do
    @@convert_constants ||= {}

    def self.add_constant_conversion(from, to)
      @@convert_constants[from] = to
    end

    def self.convert_constant(from)
      @@convert_constants[from] or from
    end

    def self.setup_constant_conversion
      (self.constants - self.superclass.constants).each do |i|
        View.add_constant_conversion i.downcase.to_sym, self.const_get(i)
      end
    end

    def configure(context, params = {})
      if width = params.delete(:width)
        getLayoutParams.width = View.convert_constant(width)
      end

      if height = params.delete(:height)
        getLayoutParams.height = View.convert_constant(height)
      end

      if layout = params.delete(:layout)
        lp = getLayoutParams
        layout.each do |k, v|
          values = (v.is_a?(Array) ? v : [v]).map { |i| @@convert_constants[i] or i }
          lp.send("#{k.to_s.gsub(/_([a-z])/) { $1.upcase }}", *values)
        end
      end

      params.each do |k, v|
        values = (v.is_a?(Array) ? v : [v]).map { |i| @@convert_constants[i] or i }
        self.send("set#{k.to_s.gsub(/(^|_)([a-z])/) { $2.upcase }}", *values)
      end
    end
end

#
# Load ViewGroup constants
#

java_import "android.view.ViewGroup"
View.add_constant_conversion :wrap_content, ViewGroup::LayoutParams::WRAP_CONTENT
View.add_constant_conversion :fill_parent, ViewGroup::LayoutParams::FILL_PARENT

#
# RubotoActivity View Generation
#

def ruboto_import_widgets(*widgets)
  widgets.each { |i| ruboto_import_widget i }
end

def ruboto_import_widget(class_name, package_name="android.widget")
  klass = java_import("#{package_name}.#{class_name}") || eval("Java::#{package_name}.#{class_name}")
  
  return unless klass

  RubotoActivity.class_eval "
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

  setup_list_view if class_name == :ListView
  setup_spinner if class_name == :Spinner
  setup_button if class_name == :Button
  setup_image_button if class_name == :ImageButton
  setup_linear_layout if class_name == :LinearLayout
  setup_relative_layout if class_name == :RelativeLayout
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
  Java::android.widget.ListView.class_eval do
    attr_reader :adapter, :adapter_list

    def configure(context, params = {})
      if params.has_key? :list
        @adapter_list = Java::java.util.ArrayList.new
        @adapter_list.addAll(params[:list])
        item_layout = params.delete(:item_layout) || R::layout::simple_list_item_1
        @adapter    = Java::android.widget.ArrayAdapter.new(context, item_layout, @adapter_list)
        setAdapter @adapter
        params.delete :list
      end
      if params.has_key? :adapter
        @adapter = params[:adapter]
      end
      super(context, params)
    end

    def reload_list(list)
      @adapter_list.clear
      @adapter_list.addAll(list)
      @adapter.notifyDataSetChanged
      invalidate
    end
  end
end

def setup_spinner
  Java::android.widget.Spinner.class_eval do
    attr_reader :adapter, :adapter_list

    def configure(context, params = {})
      if params.has_key? :list
        @adapter_list = Java::java.util.ArrayList.new
        @adapter_list.addAll(params[:list])
        item_layout = params.delete(:item_layout) || R::layout::simple_spinner_item
        @adapter    = Java::android.widget.ArrayAdapter.new(context, item_layout, @adapter_list)
        @adapter.setDropDownViewResource(params.delete(:dropdown_layout) || R::layout::simple_spinner_dropdown_item)
        setAdapter @adapter
        params.delete :list
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

