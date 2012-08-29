require 'ruboto/activity'

#######################################################
#
# ruboto/menu.rb
#
# Make using menus a little easier. This is still using
# handle methods and may be moved into legacy code.
#
#######################################################

module Ruboto
  module Activity
    #
    # Option Menus
    #
    def add_menu title, icon=nil, &block
      mi = @menu.add(title)
      mi.setIcon(icon) if icon
      mi.class.class_eval { attr_accessor :on_click }
      mi.on_click = block

      # Seems to be needed or the block might get cleaned up
      @all_menu_items = [] unless @all_menu_items
      @all_menu_items << mi
    end

    def handle_create_options_menu &block
      p = Proc.new do |*args|
        @menu = args[0]
        instance_eval { block.call(*args) } if block
      end
      scriptInfo.setCallbackProc(self.class.const_get("CB_CREATE_OPTIONS_MENU"), p)

      p = Proc.new do |num, menu_item|
        # handles a problem where this is called for context items
        # TODO(uwe): Remove check for SDK version when we stop supporting api level < 11
        unless @just_processed_context_item == menu_item || (android.os.Build::VERSION::SDK_INT >= 11 && menu_item.item_id == AndroidIds.home)
          instance_eval &(menu_item.on_click)
          @just_processed_context_item = nil
          true
        else
          false
        end
      end
      scriptInfo.setCallbackProc(self.class.const_get("CB_MENU_ITEM_SELECTED"), p)
    end

    #
    # Context Menus
    #

    def add_context_menu title, &block
      mi = @context_menu.add(title)
      mi.class.class_eval { attr_accessor :on_click }
      mi.on_click = block

      # Seems to be needed or the block might get cleaned up
      @all_menu_items = [] unless @all_menu_items
      @all_menu_items << mi
    end

    def handle_create_context_menu &block
      p = Proc.new do |*args|
        @context_menu = args[0]
        instance_eval { block.call(*args) } if block
      end
      scriptInfo.setCallbackProc(self.class.const_get("CB_CREATE_CONTEXT_MENU"), p)

      p = Proc.new do |menu_item|
        if menu_item.on_click
          arg = menu_item
          begin
            arg = menu_item.getMenuInfo.position
          rescue
          end
          instance_eval { menu_item.on_click.call(arg) }
          @just_processed_context_item = menu_item
          true
        else
          false
        end
      end
      scriptInfo.setCallbackProc(self.class.const_get("CB_CONTEXT_ITEM_SELECTED"), p)
    end
  end
end

