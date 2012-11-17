class MytestOtherfileActivity
  def on_create(bundle)
    super
    set_title 'Otherfile Activity'

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => :center_horizontal do
          text_view :text => 'This is an otherfile activity.', :id => 42, :width => :match_parent,
                    :gravity => :center, :text_size => 48.0
        end
  end
end
