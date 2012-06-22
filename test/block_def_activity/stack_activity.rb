STACK_DEPTH_SCRIPT = java.lang.Thread.current_thread.stack_trace.length.to_s
require 'ruboto'

ruboto_import_widgets :Button, :LinearLayout, :TextView

$activity.handle_create do |bundle|
  STACK_DEPTH_HANDLE_CREATE = java.lang.Thread.current_thread.stack_trace.length.to_s
  setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map{|s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

  setup_content do
    STACK_DEPTH_SETUP_CONTENT = java.lang.Thread.current_thread.stack_trace.length.to_s
    linear_layout :orientation => LinearLayout::VERTICAL do
      STACK_DEPTH_LINEAR_LAYOUT = java.lang.Thread.current_thread.stack_trace.length.to_s
      @script_view        = text_view :id => 42, :text => STACK_DEPTH_SCRIPT
      @handle_create_view = text_view :id => 43, :text => STACK_DEPTH_HANDLE_CREATE
      @setup_content_view = text_view :id => 44, :text => STACK_DEPTH_SETUP_CONTENT
      @linear_layout_view = text_view :id => 45, :text => STACK_DEPTH_LINEAR_LAYOUT
    end
  end

end
