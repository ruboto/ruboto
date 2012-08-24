require 'ruboto/util/toast'
require 'ruboto/widget'

ruboto_import_widgets :ImageButton, :LinearLayout, :TextView

class ImageButtonActivity
  def on_create(bundle)
    super
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    click_handler = proc do |view|
      @text_view.setText 'What hath Matz wrought!'
      toast 'Flipped a bit via butterfly'
    end

    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL, :gravity => android.view.Gravity::CENTER_HORIZONTAL do
          @text_view = text_view :text    => 'What hath Matz wrought?', :id => 42, :width => :fill_parent,
                                 :gravity => android.view.Gravity::CENTER, :text_size => 48.0
          image_button :image_resource    => $package.R::drawable::get_ruboto_core, :width => :wrap_content, :id => 43,
                       :on_click_listener => click_handler
        end
  end
end
