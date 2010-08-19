#######################################################
#
# ruboto.rb (by Scott Moyer)
#
# Wrapper for using RubotoActivity in Ruboto IRB
#
#######################################################

$RUBOTO_VERSION = 4

def confirm_ruboto_version(required_version, exact=true)
  raise "requires $RUBOTO_VERSION=#{required_version} or greater, current version #{$RUBOTO_VERSION}" if $RUBOTO_VERSION < required_version and not exact
  raise "requires $RUBOTO_VERSION=#{required_version}, current version #{$RUBOTO_VERSION}" if $RUBOTO_VERSION != required_version and exact
end

require 'java'



%w(Activity BroadcastReceiver).map do |klass|
  java_import "org.ruboto.Ruboto#{klass}"
end

RUBOTO_CLASSES = [RubotoActivity, RubotoBroadcastReceiver]

# Automate this?
#java_import "org.ruboto.embedded.RubotoView"

java_import "android.app.Activity"
java_import "android.content.Intent"
java_import "android.os.Bundle"

java_import "android.view.View"
java_import "android.view.ViewGroup"

java_import "android.widget.Toast"

java_import "android.widget.ArrayAdapter"
java_import "java.util.Arrays"
java_import "java.util.ArrayList"
java_import "android.R"

java_import "android.util.Log"

module Ruboto
  java_import "THE_PACKAGE.R"
  begin
    Id = JavaUtilities.get_proxy_class("THE_PACKAGE.R$id")
  rescue NameError
    Log.d "RUBOTO", "no R$id"
  end

end
AndroidIds = JavaUtilities.get_proxy_class("android.R$id")

#############################################################################
#
# Activity
#

class Activity
  attr_accessor :init_block

  def start_ruboto_dialog(remote_variable, &block)
    start_ruboto_activity(remote_variable, true, &block)
  end

  def start_ruboto_activity(remote_variable, dialog=false, &block)
    @@init_block = block

    if @initialized or not self.is_a?(RubotoActivity)
      b = Bundle.new
      b.putString("Remote Variable", remote_variable)
      b.putBoolean("Define Remote Variable", true)
      b.putString("Initialize Script", "#{remote_variable}.initialize_activity")

      i = Intent.new
      i.setClassName "THE_PACKAGE",
                     "THE_PACKAGE.ACTIVITY_NAME"
      i.putExtra("RubotoActivity Config", b)

      self.startActivity i
    else
      instance_eval "#{remote_variable}=self"
      setRemoteVariable remote_variable
      initialize_activity
      on_create nil
    end

    self
  end

  #plugin
  def toast(text, duration=5000)
    Toast.makeText(self, text, duration).show
  end

  #plugin
  def toast_result(result, success, failure, duration=5000)
    toast(result ? success : failure, duration)
  end
end

#############################################################################
#
# RubotoActivity
#

class RubotoActivity
  #
  # Initialize
  #

  def initialize_activity()
    instance_eval &@@init_block
    @initialized = true
    self
  end

  #
  # Option Menus
  #

  def add_menu title, icon=nil, &block
    mi = @menu.add(title)
    mi.setIcon(icon) if icon
    mi.class.class_eval {attr_accessor :on_click}
    mi.on_click = block
  end

  def handle_create_options_menu &block
    requestCallback RubotoActivity::CB_CREATE_OPTIONS_MENU
    @create_options_menu_block = block
  end

  def on_create_options_menu(*args)
    @menu, @context_menu = args[0], nil
    instance_eval {@create_options_menu_block.call(*args)} if @create_options_menu_block
  end

  def on_menu_item_selected(num,menu_item)
    (instance_eval &(menu_item.on_click); return true) if @menu
    false
  end

  #
  # Context Menus
  #

  def add_context_menu title, &block
    mi = @context_menu.add(title)
    mi.class.class_eval {attr_accessor :on_click}
    mi.on_click = block
  end

  def handle_create_context_menu &block
    requestCallback RubotoActivity::CB_CREATE_CONTEXT_MENU
    @create_context_menu_block = block
  end

  def on_create_context_menu(*args)
    @menu, @context_menu = nil, args[0]
    instance_eval {@create_context_menu_block.call(*args)} if @create_context_menu_block
  end

  def on_context_item_selected(menu_item)
    (instance_eval {menu_item.on_click.call(menu_item.getMenuInfo.position)}; return true) if menu_item.on_click
    false
  end
end

RUBOTO_CLASSES.each do |klass|
  klass.class_eval do
    def handle_create &block
      @create_block = block
    end

    def on_create(bundle)
      setContentView(instance_eval &@content_view_block) if @content_view_block
      instance_eval {@create_block.call} if @create_block
    end

    # plugin or something
    def setup_content &block
      @view_parent = nil
      @content_view_block = block
    end

    #
    # Setup Callbacks
    #

    def method_missing(name, *args, &block)
      # make #handle_name_of_callback request that callback
      if name.to_s =~ /^handle_(.*)/ and (const = RubotoActivity.const_get("CB_#{$1.upcase}"))
        requestCallback const
        @eigenclass ||= class << self; self; end
        @eigenclass.send(:define_method, "on_#{$1}", &block)
      else
        super
      end
    end

    def respond_to?(name)
      return true if name.to_s =~ /^handle_(.*)/ and RubotoActivity.const_get("CB_#{$1.upcase}")
      super
    end
  end
end


#############################################################################
#
# RubotoActivity View Generation
#

def ruboto_import_widgets(*widgets)
  widgets.each{|i| ruboto_import_widget i}
end

def ruboto_import_widget(class_name)
  view_class = java_import "android.widget.#{class_name}"
  return unless view_class

  RubotoActivity.class_eval "
     def #{(class_name.to_s.gsub(/([A-Z])/) {'_' + $1.downcase})[1..-1]}(params={})
        rv = #{class_name}.new self
        @view_parent.addView(rv) if @view_parent
        rv.configure self, params
        if block_given?
          old_view_parent, @view_parent = @view_parent, rv
          yield
          @view_parent = old_view_parent
        end
        rv
     end
   "
end

# Need to load these two to extend classes
ruboto_import_widgets :ListView, :Button

#############################################################################
#
# Extend Common View Classes
#

class View
  @@convert_params = {
     :wrap_content => ViewGroup::LayoutParams::WRAP_CONTENT,
     :fill_parent  => ViewGroup::LayoutParams::FILL_PARENT,
  }

  def configure(context, params = {})
    if width = params.delete(:width)
      getLayoutParams.width = @@convert_params[width] or width
    end

    if height = params.delete(:height)
      getLayoutParams.height = @@convert_params[height] or height
    end

    params.each do |k, v|
      if v.is_a?(Array)
        self.send("set#{k.to_s.gsub(/(^|_)([a-z])/) {$2.upcase}}", *v)
      else
        self.send("set#{k.to_s.gsub(/(^|_)([a-z])/) {$2.upcase}}", v)
      end
    end
  end
end

class ListView
  attr_reader :adapter, :adapter_list

  def configure(context, params = {})
    if params.has_key? :list
      @adapter_list = ArrayList.new
      @adapter_list.addAll(params[:list])
      @adapter = ArrayAdapter.new(context, R::layout::simple_list_item_1, @adapter_list)
      setAdapter @adapter
      params.delete :list
    end
    setOnItemClickListener(context)
    super(context, params)
  end

  def reload_list(list)
    @adapter_list.clear();
    @adapter_list.addAll(list)
    @adapter.notifyDataSetChanged
    invalidate
  end
end

class Button
  def configure(context, params = {})
    setOnClickListener(context)
    super(context, params)
  end
end
