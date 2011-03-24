require 'ruboto'

ruboto_import_widgets :TextView, :LinearLayout, :Button

$activity.handle_create do |bundle|
  setTitle 'This is the Title'

  setup_content do
    linear_layout :orientation => LinearLayout::VERTICAL do
      @text_view = text_view :text => "What hath Matz wrought?", :id => 42
      button :text => "M-x butterfly", :width => :wrap_content, :id => 43
    end
  end

  handle_click do |view|
    if view.getText == 'M-x butterfly'
      @text_view.setText "What hath Matz wrought!"
      toast 'Flipped a bit via butterfly'
    end
  end
end
