require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :TextView

class DirAndFileActivity
  def onCreate(bundle)
    super
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').
                 map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')
    self.content_view =
        linear_layout :orientation => :vertical do
          text_view :id => 42, :text => __FILE__
          text_view :id => 43, :text => File.dirname(__FILE__)
          text_view :id => 44, :text => Dir["#{File.dirname(__FILE__)}/*"].sort[0].to_s
          text_view :id => 45, :text => Dir.foreach(File.dirname(__FILE__)).to_a[2].to_s
        end
  end
end
