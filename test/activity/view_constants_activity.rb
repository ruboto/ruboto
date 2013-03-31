require 'ruboto/widget'

ruboto_import_widgets :Button, :LinearLayout, :TextView

class ViewConstantsActivity
  def onCreate(bundle)
    super
    $ruboto_test_app_activity = self
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view =
        linear_layout :orientation => :vertical do
          @text_view = text_view :text    => 'What hath Matz wrought?', :id => 42, :width => :fill_parent,
                                 :gravity => android.view.Gravity::CENTER, :text_size => 48.0
          button :text => 'M-x butterfly', :width => :fill_parent, :id => 43, :on_click_listener => proc { butterfly }
        end
  rescue
    puts "Exception creating activity: \#{$!}"
    puts $!.backtrace.join("\\n")
  end

  def set_text(text)
    @text_view.text = text
  end

  private

  def butterfly
    puts 'butterfly'
    Thread.start do
      begin
        startService(android.content.Intent.new(application_context, $package.RubotoTestService.java_class))
      rescue Exception
        puts "Exception starting the service: \#{$!}"
        puts $!.backtrace.join("\\n")
      end
    end
    puts 'butterfly OK'
  end

end
