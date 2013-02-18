require 'ruboto/widget'

java_import android.location.Location

ruboto_import_widgets :LinearLayout, :TextView

class LocationActivity
  def onCreate(bundle)
    super
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')
    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL, :gravity => android.view.Gravity::CENTER do
          @distance_text = text_view :id => 42,
                    :text_size => 48.0, :gravity => android.view.Gravity::CENTER
          @start_bearing_text = text_view :id => 43,
                    :text_size => 48.0, :gravity => android.view.Gravity::CENTER
          @end_bearing_text = text_view :id => 44,
                    :text_size => 48.0, :gravity => android.view.Gravity::CENTER
        end
  end

  def onResume
    super
    result = Array.new(3, 0.0).to_java(:float)
    Location.distanceBetween(59.0, 11.0, 59.1, 11.1, result)
    @distance_text.text = result[0].to_s
    @start_bearing_text.text = result[1].to_s
    @end_bearing_text.text = result[2].to_s
  end
end
