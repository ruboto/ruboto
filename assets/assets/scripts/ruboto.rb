#######################################################
#
# ruboto.rb (by Scott Moyer)
#
# - Wrapper for using RubotoActivity, RubotoService, and
#     RubotoBroadcastReceiver. 
# - Provides interface for generating UI elements. 
# - Imports and configures callback classes.
#
#######################################################

$RUBOTO_VERSION = 7

def confirm_ruboto_version(required_version, exact=true)
  raise "requires $RUBOTO_VERSION=#{required_version} or greater, current version #{$RUBOTO_VERSION}" if $RUBOTO_VERSION < required_version and not exact
  raise "requires $RUBOTO_VERSION=#{required_version}, current version #{$RUBOTO_VERSION}" if $RUBOTO_VERSION != required_version and exact
end

require 'java'

$package_name = "THE_PACKAGE"

class Object
  def self.android
    Java::android
  end

  def android
    self.class.android
  end
end

java_import "android.R"

module Ruboto
  java_import "#{$package_name}.R"
  begin
    Id = JavaUtilities.get_proxy_class("#{$package_name}.R$id")
  rescue NameError
    Java::android.util.Log.d "RUBOTO", "no R$id"
  end
end
AndroidIds = JavaUtilities.get_proxy_class("android.R$id")

#############################################################################
#
# Activity
#

def setup_activity
 java_import "android.app.Activity"

 Activity.class_eval do
  def start_ruboto_dialog(remote_variable, &block)
    start_ruboto_activity(remote_variable, RubotoDialog, &block)
  end

  def start_ruboto_activity(remote_variable, klass=RubotoActivity, &block)
    $activity_init_block = block

    if @initialized or self == $activity
      b = Java::android.os.Bundle.new
      b.putString("Remote Variable", remote_variable)
      b.putBoolean("Define Remote Variable", true)
      b.putString("Initialize Script", "#{remote_variable}.initialize_activity")

      i = Java::android.content.Intent.new
      i.setClass self, klass.java_class
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
    Java::android.widget.Toast.makeText(self, text, duration).show
  end

  #plugin
  def toast_result(result, success, failure, duration=5000)
    toast(result ? success : failure, duration)
  end
 end
end

#############################################################################
#
# Configure a class to work with handlers
#

def ruboto_allow_handlers(klass)
  klass.class_eval do
    def method_missing(name, *args, &block)
      if name.to_s =~ /^handle_(.*)/ and (const = self.class.const_get("CB_#{$1.upcase}"))
        setCallbackProc(const, block)
        self
      else
        super
      end
    end

    def respond_to?(name)
      return true if name.to_s =~ /^handle_(.*)/ and self.class.const_get("CB_#{$1.upcase}")
      super
    end

    def initialize_handlers(&block)
      instance_eval &block
      self
    end
  end
  klass
end

#############################################################################
#
# Activity Subclass Setup
#

def ruboto_configure_activity(klass)
  klass.class_eval do
    #
    # Initialize
    #

    def initialize_activity()
      instance_eval &$activity_init_block
      @initialized = true
      self
    end

    def handle_finish_create &block
      @finish_create_block = block
    end

    def setup_content &block
      @content_view_block = block
    end

    def on_create(bundle)
      @view_parent = nil
      setContentView(instance_eval &@content_view_block) if @content_view_block
      instance_eval {@finish_create_block.call} if @finish_create_block
    end

    #
    # Option Menus
    #

    def add_menu title, icon=nil, &block
      mi = @menu.add(title)
      mi.setIcon(icon) if icon
      mi.class.class_eval {attr_accessor :on_click}
      mi.on_click = block

      # Seems to be needed or the block might get cleaned up
      @all_menu_items = [] unless @all_menu_items
      @all_menu_items << mi
    end

    def handle_create_options_menu &block
      p = Proc.new do |*args|
        @menu, @context_menu = args[0], nil
        instance_eval {block.call(*args)} if block
      end
      setCallbackProc(self.class.const_get("CB_CREATE_OPTIONS_MENU"), p)

      p = Proc.new do |num,menu_item|
        (instance_eval &(menu_item.on_click); return true) if @menu
        false
      end
      setCallbackProc(self.class.const_get("CB_MENU_ITEM_SELECTED"), p)
    end

    #
    # Context Menus
    #

    def add_context_menu title, &block
      mi = @context_menu.add(title)
      mi.class.class_eval {attr_accessor :on_click}
      mi.on_click = block

      # Seems to be needed or the block might get cleaned up
      @all_menu_items = [] unless @all_menu_items
      @all_menu_items << mi
    end

    def handle_create_context_menu &block
      p = Proc.new do |*args|
        @menu, @context_menu = nil, args[0]
        instance_eval {block.call(*args)} if block
      end
      setCallbackProc(self.class.const_get("CB_CREATE_CONTEXT_MENU"), p)

      p = Proc.new do |menu_item|
        (instance_eval {menu_item.on_click.call(menu_item.getMenuInfo.position)}; return true) if menu_item.on_click
        false
      end
      setCallbackProc(self.class.const_get("CB_CONTEXT_ITEM_SELECTED"), p)
    end
  end

  ruboto_allow_handlers(klass)
end

#############################################################################
#
# Ruboto Set up for all app types (Activity, Service, BroadcastReceiver)
#

def ruboto_setup(klass, init_method="create")
  # Setup ability to handle callbacks
  ruboto_allow_handlers(klass)

  klass.class_eval do
    def when_launched(&block)
      instance_exec *args, &block
      on_create nil
    end

    eval %Q{
      def handle_#{init_method}(&block)
        when_launched &block
      end
    }
  end
end

#############################################################################
#
# RubotoActivity View Generation
#

def ruboto_import_widgets(*widgets)
  widgets.each{|i| ruboto_import_widget i}
end

def ruboto_import_widget(class_name, package_name="android.widget")
  view_class = java_import "#{package_name}.#{class_name}"
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

  setup_list_view       if class_name == :ListView
  setup_button          if class_name == :Button
  setup_linear_layout   if class_name == :LinearLayout
  setup_relative_layout if class_name == :RelativeLayout
end

#############################################################################
#
# Extend Common View Classes
#

def setup_view
 java_import "android.view.View"
 java_import "android.view.ViewGroup"

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
        values = (v.is_a?(Array) ? v : [v]).map{|i| @@convert_constants[i] or i}
        lp.send("#{k.to_s.gsub(/_([a-z])/) {$1.upcase}}", *values)
      end
    end

    params.each do |k, v|
      values = (v.is_a?(Array) ? v : [v]).map{|i| @@convert_constants[i] or i}
      self.send("set#{k.to_s.gsub(/(^|_)([a-z])/) {$2.upcase}}", *values)
    end
  end
 end

 View.add_constant_conversion :wrap_content, ViewGroup::LayoutParams::WRAP_CONTENT
 View.add_constant_conversion :fill_parent,  ViewGroup::LayoutParams::FILL_PARENT
end

#############################################################################
#
# Special widget setup
#

def setup_linear_layout
  LinearLayout.setup_constant_conversion
end

def setup_relative_layout
  RelativeLayout.setup_constant_conversion
end

def setup_button
  Button.class_eval do
    def configure(context, params = {})
      setOnClickListener(context)
      super(context, params)
    end
  end

  ruboto_register_handler("org.ruboto.callbacks.RubotoOnClickListener", "click", Button, "setOnClickListener")
end

def setup_list_view
  ListView.class_eval do
    attr_reader :adapter, :adapter_list

    def configure(context, params = {})
      if params.has_key? :list
        @adapter_list = Java::java.util.ArrayList.new
        @adapter_list.addAll(params[:list])
        @adapter = Java::android.widget.ArrayAdapter.new(context, R::layout::simple_list_item_1, @adapter_list)
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

  ruboto_register_handler("org.ruboto.callbacks.RubotoOnItemClickListener", "item_click", ListView, "setOnItemClickListener")
end

#############################################################################
#
# Import a class and set it up for handlers
#

def ruboto_import(package_class)
  klass = java_import package_class
  return unless klass
  ruboto_allow_handlers(klass)
end

#############################################################################
#
# Allows RubotoActivity to handle callbacks covering Class based handlers
#

def ruboto_register_handler(handler_class, unique_name, for_class, method_name)
  klass_name = handler_class[/.+\.([A-Z].+)/,1]
  klass = ruboto_import handler_class
  return unless klass

  RubotoActivity.class_eval "
    attr_accessor :#{unique_name}_handler

    def #{unique_name}_handler
      @#{unique_name}_handler ||= #{klass_name}.new
    end

    def handle_#{unique_name}(&block)
      #{unique_name}_handler.handle_#{unique_name} &block
      self
    end
  "

  for_class.class_eval "
    alias_method :orig_#{method_name}, :#{method_name}
    def #{method_name}(handler)
      orig_#{method_name}(handler.kind_of?(RubotoActivity) ? handler.#{unique_name}_handler : handler)
    end
  "
end

#############################################################################
#
# RubotoPreferenceActivity Preference Generation
#

def ruboto_import_preferences(*preferences)
  preferences.each{|i| ruboto_import_preference i}
end

def ruboto_import_preference(class_name, package_name="android.preference")
  klass = java_import "#{package_name}.#{class_name}"
  return unless klass

  setup_preferences

  RubotoPreferenceActivity.class_eval "
     def #{(class_name.to_s.gsub(/([A-Z])/) {'_' + $1.downcase})[1..-1]}(params={})
        rv = #{class_name}.new self
        rv.configure self, params
        @parent.addPreference(rv) if @parent
        if block_given?
          old_parent, @parent = @parent, rv
          yield
          @parent = old_parent
        end
        rv
     end
   "
end

def setup_preferences
  return if @preferences_setup_complete

  java_import "android.preference.PreferenceScreen"
  java_import "android.preference.Preference"
  java_import "org.ruboto.RubotoPreferenceActivity"
  ruboto_configure_activity(RubotoPreferenceActivity)


  RubotoPreferenceActivity.class_eval do
    def preference_screen(params={})
      rv = self.getPreferenceManager.createPreferenceScreen(self)
      rv.configure self, params
      @parent.addPreference(rv) if @parent
      if block_given?
        old_parent, @parent = @parent, rv
        yield
        @parent = old_parent
      end
      rv
    end

    def setup_preference_screen &block
      @preference_screen_block = block
    end

    def on_create(bundle)
      @parent = nil
      setPreferenceScreen(instance_eval &@preference_screen_block) if @preference_screen_block
      instance_eval {@finish_create_block.call} if @finish_create_block
    end
  end

  Preference.class_eval do
    def configure(context, params = {})
      params.each do |k, v|
        if v.is_a?(Array)
          self.send("set#{k.to_s.gsub(/(^|_)([a-z])/) {$2.upcase}}", *v)
        else
          self.send("set#{k.to_s.gsub(/(^|_)([a-z])/) {$2.upcase}}", v)
        end
      end
    end
  end

  @preferences_setup_complete = true
end

#############################################################################
#############################################################################
#
# Final set up depending on globals
#

if $activity
  java_import "org.ruboto.RubotoActivity"
  setup_activity
  ruboto_configure_activity(RubotoActivity)
  ruboto_setup(RubotoActivity)
  setup_view
end

if $service
  java_import "org.ruboto.RubotoService"
  ruboto_setup(RubotoService)
end

if $broadcast_receiver
  java_import "org.ruboto.RubotoBroadcastReceiver"
  ruboto_setup(RubotoBroadcastReceiver, "receive")
end

