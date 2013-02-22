require 'ruboto/widget'

ruboto_import_widgets :Button, :LinearLayout, :TextView

class ConstantsActivity
  def onCreate(bundle)
    super
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view =
        linear_layout :orientation => :vertical,
                      :gravity => android.view.Gravity::CENTER do
          text_view :id => 42, :text_size => 48.0, :gravity => android.view.Gravity::CENTER,
                    :text => __FILE__
        end
  end
end
