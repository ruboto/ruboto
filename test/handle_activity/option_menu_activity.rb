STACK_DEPTH_SCRIPT = java.lang.Thread.current_thread.stack_trace.length.to_s

raise "Stack level: #{STACK_DEPTH_SCRIPT}" rescue puts $!.message + "\n" + $!.backtrace.join("\n")

require 'ruboto'

ruboto_import_widgets :ImageButton, :LinearLayout, :TextView

$activity.handle_create do |bundle|
  setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map{|s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

  setup_content do
    linear_layout :orientation => LinearLayout::VERTICAL do
      @text_view = text_view :text => 'What hath Matz wrought?', :id => 42
    end
  end

  handle_create_options_menu do |menu|
    add_menu('Test') do
      @text_view.setText 'What hath Matz wrought!'
      toast 'Flipped a bit via butterfly'
    end
    true
  end
end
