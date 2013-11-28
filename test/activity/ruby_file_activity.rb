class RubyFileActivity
  def onCreate(bundle)
    super
    set_title 'Ruby file Activity'
    display_text = intent.get_extra('extra_string') || 'This is a Ruby file activity.'

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => :center_horizontal do
          text_view :text => display_text, :id => 42, 
                    :layout => {:width => :match_parent},
                    :gravity => :center, :text_size => 48.0
        end
  end
end
