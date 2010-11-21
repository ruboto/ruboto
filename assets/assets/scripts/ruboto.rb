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

$RUBOTO_VERSION = 6

def confirm_ruboto_version(required_version, exact=true)
  raise "requires $RUBOTO_VERSION=#{required_version} or greater, current version #{$RUBOTO_VERSION}" if $RUBOTO_VERSION < required_version and not exact
  raise "requires $RUBOTO_VERSION=#{required_version}, current version #{$RUBOTO_VERSION}" if $RUBOTO_VERSION != required_version and exact
end

require 'java'



%w(Activity Dialog BroadcastReceiver Service).map do |klass|
  java_import "org.ruboto.Ruboto#{klass}"
end

RUBOTO_CLASSES = [RubotoActivity, RubotoBroadcastReceiver, RubotoService]
$init_methods = Hash.new 'create'
$init_methods[RubotoBroadcastReceiver] = 'receive'

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
    start_ruboto_activity(remote_variable, RubotoDialog, &block)
  end

  def start_ruboto_activity(remote_variable, klass=RubotoActivity, &block)
    @@init_block = block

    if @initialized or not self.is_a?(RubotoActivity)
      b = Bundle.new
      b.putString("Remote Variable", remote_variable)
      b.putBoolean("Define Remote Variable", true)
      b.putString("Initialize Script", "#{remote_variable}.initialize_activity")

      i = Intent.new
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

    # Seems to be needed or the block might get cleaned up
    @all_menu_items = [] unless @all_menu_items
    @all_menu_items << mi
  end

  def handle_create_options_menu &block
    p = Proc.new do |*args|
      @menu, @context_menu = args[0], nil
      instance_eval {block.call(*args)} if block
    end
    setCallbackProc(RubotoActivity::CB_CREATE_OPTIONS_MENU, p)

    p = Proc.new do |num,menu_item|
      (instance_eval &(menu_item.on_click); return true) if @menu
      false
    end
    setCallbackProc(RubotoActivity::CB_MENU_ITEM_SELECTED, p)
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
    setCallbackProc(RubotoActivity::CB_CREATE_CONTEXT_MENU, p)

    p = Proc.new do |menu_item|
      (instance_eval {menu_item.on_click.call(menu_item.getMenuInfo.position)}; return true) if menu_item.on_click
      false
    end
    setCallbackProc(RubotoActivity::CB_CONTEXT_ITEM_SELECTED, p)
  end
end

RUBOTO_CLASSES.each do |klass|
  klass.class_eval do
    def when_launched(&block)
      instance_exec *args, &block
      on_create nil
    end

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

    eval %Q{
      def handle_#{$init_methods[klass]}(&block)
        when_launched &block
      end
    }
  end
end

#############################################################################
#
# ruboto_import
#

def ruboto_import(package_class)
  klass = java_import package_class
  return unless klass

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
end

#############################################################################
#
# Extend Common View Classes
#

# Need to load these two to extend classes
ruboto_import_widgets :ListView, :Button

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
    setOnItemClickListener(context.item_click_handler)
    super(context, params)
  end

  def reload_list(list)
    @adapter_list.clear();
    @adapter_list.addAll(list)
    @adapter.notifyDataSetChanged
    invalidate
  end
end

ruboto_import "org.ruboto.RubotoOnItemClickListener"

class RubotoActivity
  attr_accessor :item_click_handler

  def item_click_handler
    @item_click_handler ||= RubotoOnItemClickListener.new
  end

  def handle_item_click(&block)
    item_click_handler.send(:handle_item_click, &block)
    self
  end
end

class Button
  def configure(context, params = {})
    setOnClickListener(context.click_handler)
    super(context, params)
  end
end

ruboto_import "org.ruboto.RubotoOnClickListener"

class RubotoActivity
  attr_accessor :click_handler

  def click_handler
    @click_handler ||= RubotoOnClickListener.new
  end

  def handle_click(&block)
    click_handler.send(:handle_click, &block)
    self
  end
end

