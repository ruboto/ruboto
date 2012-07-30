require 'ruboto/activity'
require 'ruboto/widget'

ruboto_import_widgets :Button, :LinearLayout, :TextView

class NavigationByClassNameActivity
  def on_create(bundle)
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => :center_horizontal do
          text_view :text => 'What hath Matz wrought?', :id => 42, :width => :match_parent,
                    :gravity => :center, :text_size => 48.0
          button :text => 'Next by Java class', :width => :match_parent, :id => 43, :on_click_listener => proc { start_next_java_activity }
          button :text => 'Next by Ruby class', :width => :match_parent, :id => 44, :on_click_listener => proc { start_next_ruby_activity }
          button :text => 'Inline block', :width => :match_parent, :id => 45, :on_click_listener => proc { start_inline_activity }
          button :text => 'Infile class', :width => :match_parent, :id => 46, :on_click_listener => proc { start_infile_activity }
        end
  end

  private

  def start_next_java_activity
    i = android.content.Intent.new
    i.setClassName($package_name, 'org.ruboto.test_app.NavigationByClassNameActivity')
    startActivity(i)
  end

  def start_next_ruby_activity
    i = android.content.Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    configBundle = android.os.Bundle.new
    configBundle.put_string('ClassName', 'NavigationByClassNameActivity')
    i.putExtra('RubotoActivity Config', configBundle)
    startActivity(i)
  end

  def start_inline_activity
    start_ruboto_activity('$inline_activity') do
      def on_create(bundle)
        set_title 'Inline Activity'

        self.content_view =
            linear_layout :orientation => :vertical, :gravity => :center_horizontal do
              text_view :text => 'This is an inline activity.', :id => 42, :width => :match_parent,
                        :gravity => :center, :text_size => 48.0
            end
      end
    end
    nil
  end

  def start_infile_activity
    i = android.content.Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    configBundle = android.os.Bundle.new
    configBundle.put_string('ClassName', 'InfileActivity')
    i.putExtra('RubotoActivity Config', configBundle)
    startActivity(i)
  end

end

class InfileActivity
  include Ruboto::Activity

  def on_create(bundle)
    set_title 'Infile Activity'

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => :center_horizontal do
          text_view :text => 'This is an infile activity.', :id => 42, :width => :match_parent,
                    :gravity => :center, :text_size => 48.0
        end
  end
end
