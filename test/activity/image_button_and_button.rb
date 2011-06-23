require 'ruboto'

ruboto_import_widgets :Button, :ImageButton, :LinearLayout, :TextView

$activity.handle_create do |bundle|
  setTitle 'This is the Title'

  setup_content do
    linear_layout :orientation => LinearLayout::VERTICAL do
      @text_view = text_view :text => 'What hath Matz wrought?', :id => 42
      button :text => 'Button', :width => :wrap_content, :id => 44
      image_button :image_resource => $package.R::drawable::icon, :width => :wrap_content, :id => 43
    end
  end

  handle_click do |view|
    if view.id == 43
      @text_view.text = 'Image button pressed'
    elsif view.id == 44
      @text_view.text = 'Button pressed'
    end
  end

#  handle_image_click do |view|
#    if view.id == 43
#      @text_view.text = 'Image button pressed'
#    elsif view.id == 44
#      @text_view.text = 'Button pressed'
#    end
#  end
end
