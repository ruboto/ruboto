STACK_DEPTH_SCRIPT = java.lang.Thread.current_thread.stack_trace.length.to_s
require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

ruboto_import_widgets :Button, :LinearLayout, :TextView

$activity.start_ruboto_activity do
  STACK_DEPTH_START_RUBOTO_ACTIVITY = java.lang.Thread.current_thread.stack_trace.length.to_s

  def on_create(bundle)
    stack_depth_on_create = java.lang.Thread.current_thread.stack_trace.length.to_s
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL do
          stack_depth_linear_layout = java.lang.Thread.current_thread.stack_trace.length.to_s
          text_view :id => 42, :text => STACK_DEPTH_SCRIPT
          text_view :id => 43, :text => STACK_DEPTH_START_RUBOTO_ACTIVITY
          text_view :id => 44, :text => stack_depth_on_create
          text_view :id => 45, :text => stack_depth_linear_layout
        end
  end

end
