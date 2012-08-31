require 'ruboto/activity'
require 'ruboto/widget'

ruboto_import_widgets :Button, :LinearLayout, :TextView

class NavigationActivity < Java::OrgRuboto::EntryPointActivity
  def on_create(bundle)
    super
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => :center_horizontal do
          text_view :text => 'What hath Matz wrought?', :id => 42, :width => :match_parent,
                    :gravity => :center, :text_size => 48.0
          button :text => 'Next by Java class', :width => :match_parent, :id => 43, :on_click_listener => proc { start_next_java_activity }
          button :text => 'Next by Ruby class', :width => :match_parent, :id => 44, :on_click_listener => proc { start_next_ruby_activity }
          button :text => 'Next by script name', :width => :match_parent, :id => 45, :on_click_listener => proc { start_activity_by_script_name }
          button :text => 'Inline block', :width => :match_parent, :id => 46, :on_click_listener => proc { start_inline_activity }
          button :text => 'Inline block with options', :width => :match_parent, :id => 47, :on_click_listener => proc { start_inline_activity_with_options }
          button :text => 'Infile class', :width => :match_parent, :id => 48, :on_click_listener => proc { start_infile_activity }
        end
  end

  private

  def start_next_java_activity
    i = android.content.Intent.new
    i.setClassName($package_name, 'org.ruboto.test_app.NavigationActivity')
    startActivity(i)
  end

  def start_next_ruby_activity
    i = android.content.Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    configBundle = android.os.Bundle.new
    configBundle.put_string('ClassName', 'NavigationActivity')
    i.putExtra('RubotoActivity Config', configBundle)
    startActivity(i)
  end

  def start_activity_by_script_name
    i = android.content.Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    configBundle = android.os.Bundle.new
    configBundle.put_string('Script', 'navigation_activity.rb')
    i.putExtra('RubotoActivity Config', configBundle)
    startActivity(i)
  end

  def start_inline_activity
    start_ruboto_activity do
      def on_create(bundle)
        super
        set_title 'Inline Activity'
        self.content_view =
            linear_layout :orientation => :vertical, :gravity => :center_horizontal do
              text_view :text => 'This is an inline activity.', :id => 42, :width => :match_parent,
                        :gravity => :center, :text_size => 48.0
            end
      end
    end
  end

  def start_inline_activity_with_options
    start_ruboto_activity(:class_name => 'InlineActivity') do
      def on_create(bundle)
        super
        set_title 'Inline Activity'
        self.content_view =
            linear_layout :orientation => :vertical, :gravity => :center_horizontal do
              text_view :text => 'This is an inline activity.', :id => 42, :width => :match_parent,
                        :gravity => :center, :text_size => 48.0
            end
      end
    end
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
  def on_create(bundle)
    super
    set_title 'Infile Activity'

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => :center_horizontal do
          text_view :text => 'This is an infile activity.', :id => 42, :width => :match_parent,
                    :gravity => :center, :text_size => 48.0
        end
  end
end
