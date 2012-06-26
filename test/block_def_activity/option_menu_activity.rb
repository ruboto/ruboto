require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

ruboto_import_widgets :LinearLayout, :TextView

$activity.start_ruboto_activity do
  setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map{|s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

  def on_create(bundle)
    self.content_view =
    linear_layout :orientation => LinearLayout::VERTICAL do
      @text_view = text_view :text => 'What hath Matz wrought?', :id => 42
    end
  end

  def on_create_options_menu(menu)
    mi = menu.add('Test')
    mi.setIcon($package.R::drawable::get_ruboto_core)
    mi.set_on_menu_item_click_listener do |menu_item|
      @text_view.text = 'What hath Matz wrought!'
      toast 'Flipped a bit via butterfly'
    end
    true
  end
end
