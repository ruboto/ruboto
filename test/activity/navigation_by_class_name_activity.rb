require 'ruboto/widget'

ruboto_import_widgets :ImageButton, :LinearLayout, :TextView

class NavigationByClassNameActivity
  def on_create(bundle)
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => :center_horizontal do
          text_view :text => 'What hath Matz wrought?', :id => 42, :width => :match_parent,
                    :gravity => :center, :text_size => 48.0
          button :text => 'Next', :width => :wrap_content, :id => 43, :on_click_listener => proc { start_next_activity }
          button :text => 'Inline', :width => :wrap_content, :id => 44, :on_click_listener => proc { start_inline_activity }
        end
  end

  private

  def start_next_activity
    i = android.content.Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    configBundle = android.os.Bundle.new
    configBundle.put_string('ClassName', 'ImageButtonActivity')
    i.putExtra('RubotoActivity Config', configBundle)
    startActivity(i)
  end

  def start_inline_activity
    i = android.content.Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    configBundle = android.os.Bundle.new
    configBundle.put_string('ClassName', 'InlineActivity')
    i.putExtra('RubotoActivity Config', configBundle)
    startActivity(i)
  end

end

class InlineActivity
  def on_create(bundle)
    set_title 'Inline Activity'

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => :center_horizontal do
          text_view :text => 'This is an inline activity.', :id => 42, :width => :match_parent,
                    :gravity => :center, :text_size => 48.0
        end
  end
end
