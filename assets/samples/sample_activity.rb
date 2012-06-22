require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

ruboto_import_widgets :Button, :LinearLayout, :TextView

# http://xkcd.com/378/

class SampleActivity
  include Ruboto::Activity

  def on_create(bundle)
    set_title 'Domo arigato, Mr Ruboto!'

    self.content_view =
        linear_layout :orientation => :vertical do
          @text_view = text_view :text    => 'What hath Matz wrought?', :id => 42, :width => :fill_parent,
                                 :gravity => android.view.Gravity::CENTER, :text_size => 48.0
          button :text => 'M-x butterfly', :width => :fill_parent, :id => 43, :on_click_listener => proc { butterfly }
        end
  rescue
    puts "Exception creating activity: #{$!}"
    puts $!.backtrace.join("\n")
  end

  private

  def butterfly
    @text_view.text = 'What hath Matz wrought!'
    toast 'Flipped a bit via butterfly'
  end

end
