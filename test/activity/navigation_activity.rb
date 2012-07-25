require 'ruboto/activity'
require 'ruboto/widget'

ruboto_import_widgets :ImageButton, :LinearLayout, :TextView

class NavigationActivity
  def on_create(bundle)
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL, :gravity => android.view.Gravity::CENTER_HORIZONTAL do
          @text_view = text_view :text    => 'What hath Matz wrought?', :id => 42, :width => :fill_parent,
                                 :gravity => android.view.Gravity::CENTER, :text_size => 48.0
          image_button :image_resource    => $package.R::drawable::get_ruboto_core, :width => :wrap_content, :id => 43,
                       :on_click_listener => proc{start_next_activity}
        end
  end

  private

  def start_next_activity
    i = android.content.Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    configBundle = android.os.Bundle.new
    configBundle.put_string('Script', 'image_button_activity.rb')
    i.putExtra("RubotoActivity Config", configBundle)
    startActivity(i)
  end

end
