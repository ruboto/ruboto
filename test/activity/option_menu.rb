require 'ruboto'

ruboto_import_widgets :ImageButton, :LinearLayout, :TextView

$activity.handle_create do |bundle|
  setTitle 'This is the Title'

  setup_content do
    linear_layout :orientation => LinearLayout::VERTICAL do
      @text_view = text_view :text => 'What hath Matz wrought?', :id => 42
    end
  end

  handle_create_options_menu do |menu|
    add_menu('Test') do
      @text_view.setText 'What hath Matz wrought!'
      toast 'Flipped a bit via butterfly'
    end
    true
  end
end
