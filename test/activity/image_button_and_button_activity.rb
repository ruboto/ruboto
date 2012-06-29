require 'ruboto/activity'

ruboto_import_widgets :Button, :ImageButton, :LinearLayout, :TextView

class ImageButtonAndButtonActivity
  include Ruboto::Activity

  def on_create(bundle)
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL, :gravity => android.view.Gravity::CENTER_HORIZONTAL do
          @text_view = text_view :text  => 'What hath Matz wrought?', :id => 42, :text_size => 48.0,
                                 :width => :fill_parent, :gravity => android.view.Gravity::CENTER
          button :text              => 'Button', :id => 44, :text_size => 48.0,
                 :width             => :fill_parent, :gravity => android.view.Gravity::CENTER,
                 :on_click_listener => proc { @text_view.text = 'Button pressed' }
          image_button :image_resource    => $package.R::drawable::get_ruboto_core, :id => 43, :width => :wrap_content,
                       :on_click_listener => proc { @text_view.text = 'Image button pressed' }
        end
  end
end
