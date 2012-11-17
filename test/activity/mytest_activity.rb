require 'ruboto/activity'
require 'ruboto/widget'

ruboto_import_widgets :Button, :LinearLayout, :TextView

class MytestActivity < Java::OrgRuboto::EntryPointActivity
  def on_create(bundle)
    super
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').
                  map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => :center_horizontal do
          text_view :text => 'What hath Matz wrought?', :id => 42, :width => :match_parent,
                    :gravity => :center, :text_size => 48.0
          button :text => 'Infile class', :width => :match_parent, :id => 48,
                 :on_click_listener => proc { start_infile_activity }
          button :text => 'Otherfile class', :width => :match_parent, :id => 49,
                 :on_click_listener => proc { start_otherfile_activity }
        end
  end

  private

  def start_infile_activity
    i = android.content.Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    configBundle = android.os.Bundle.new
    configBundle.put_string('ClassName', 'MytestInfileActivity')
    i.putExtra('RubotoActivity Config', configBundle)
    startActivity(i)
  end

  def start_otherfile_activity
    i = android.content.Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    configBundle = android.os.Bundle.new
    configBundle.put_string('ClassName', 'MytestOtherfileActivity')
    i.putExtra('RubotoActivity Config', configBundle)
    startActivity(i)
  end

end

class MytestInfileActivity
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
