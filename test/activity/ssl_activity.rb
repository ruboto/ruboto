require 'ruboto/util/stack'
require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :TextView

class SslActivity
  def onCreate(bundle)
    super
    puts 'start thread'
    @thread = Thread.with_large_stack { require 'net/https' }
    puts 'thread started'
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')
    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL, :gravity => android.view.Gravity::CENTER do
          @text_view = text_view :id => 42, :text => 'net/https loading...',
                    :text_size => 48.0, :gravity => android.view.Gravity::CENTER
        end
  end

  def onResume
    super
    puts 'on resume my lord'
    Thread.start do
      puts 'joining thread'
      @thread.join
      puts 'thread joined'
      run_on_ui_thread{@text_view.text = 'net/https loaded OK!'}
      puts 'text updated'
    end
  end
end
