require 'ruboto'

ruboto_import_widgets :Button, :LinearLayout, :TextView

$activity.handle_create do |bundle|
  setTitle 'This is the Title'

  setup_content do
    linear_layout :orientation => :vertical do
      @text_view = text_view :text => 'What hath Matz wrought?', :id => 42
      button :text => 'M-x butterfly', :width => :wrap_content, :id => 43, :on_click_listener => @handle_click
    end
  end

  @handle_click = proc do |view|
    @text_view.text = 'What hath Matz wrought!'
    toast 'Flipped a bit via butterfly'
  end
end
