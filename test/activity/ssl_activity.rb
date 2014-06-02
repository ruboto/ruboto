require 'ruboto/util/stack'
require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :TextView

class SslActivity
  def onCreate(bundle)
    super
    puts 'start thread'
    @thread = Thread.with_large_stack { require 'net/https' }
    @open_uri_thread = Thread.with_large_stack { require 'open-uri' }
    puts 'thread started'
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')
    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL, :gravity => android.view.Gravity::CENTER do
          @text_view = text_view text: 'net/https loading...',
              text_size: 48.0, gravity: :center, id: 42
          @response_view = text_view text: 'net/https loading...',
              text_size: 48.0, gravity: :center, id: 43
        end
  end

  def onResume
    super
    Thread.with_large_stack do
      begin
        @thread.join
        run_on_ui_thread { @text_view.text = 'net/https loaded OK!' }
        @open_uri_thread.join
        run_on_ui_thread { @response_view.text = 'open-uri loaded OK!' }
        puts 'before open'
        open('https://google.com/', ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE) do |f|
          puts 'inside open'
          body = f.read
          puts 'body'
          puts body
          heading = body[%r{<title>.*?</title>}]
          puts heading.inspect
          run_on_ui_thread { @response_view.text = heading }
        end
      rescue Exception
        puts "Exception resdum: #{$!.class} #{$!.message}"
        run_on_ui_thread { @response_view.text = $!.to_s }
      end
    end
  end
end
