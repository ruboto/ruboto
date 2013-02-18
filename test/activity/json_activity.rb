require 'ruboto/util/stack'
with_large_stack { require 'json' }
require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :TextView

class JsonActivity
  def onCreate(bundle)
    super
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')
    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL, :gravity => android.view.Gravity::CENTER do
          text_view :id => 42, :text => with_large_stack { JSON.load('["foo"]')[0] },
                    :text_size => 48.0, :gravity => android.view.Gravity::CENTER
          text_view :id => 43, :text => with_large_stack { JSON.dump(['foo']) },
                    :text_size => 48.0, :gravity => android.view.Gravity::CENTER
          text_view :id => 44, :text => with_large_stack { 'foo'.to_json },
                    :text_size => 48.0, :gravity => android.view.Gravity::CENTER
        end
  end
end
