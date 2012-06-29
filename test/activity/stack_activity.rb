STACK_DEPTH_SCRIPT = java.lang.Thread.current_thread.stack_trace.length.to_s

require 'ruboto/activity'

ruboto_import_widgets :Button, :LinearLayout, :TextView

class StackActivity
  STACK_DEPTH_CLASS = java.lang.Thread.current_thread.stack_trace.length.to_s
  include Ruboto::Activity

  def on_create(bundle)
    stack_depth_on_create = java.lang.Thread.current_thread.stack_trace.length.to_s
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view =
        linear_layout :orientation => :vertical do
          stack_depth_linear_layout = java.lang.Thread.current_thread.stack_trace.length.to_s
          @script_view              = text_view :id => 42, :text => STACK_DEPTH_SCRIPT, :text_size => 48.0, :gravity => android.view.Gravity::CENTER
          @class_view               = text_view :id => 43, :text => STACK_DEPTH_CLASS, :text_size => 48.0, :gravity => android.view.Gravity::CENTER
          @handle_create_view       = text_view :id => 44, :text => stack_depth_on_create, :text_size => 48.0, :gravity => android.view.Gravity::CENTER
          @linear_layout_view       = text_view :id => 45, :text => stack_depth_linear_layout, :text_size => 48.0, :gravity => android.view.Gravity::CENTER
        end
  end
end
