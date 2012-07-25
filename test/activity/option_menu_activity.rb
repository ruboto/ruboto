require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

ruboto_import_widgets :LinearLayout, :TextView

class OptionMenuActivity
  def on_create(bundle)
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL do
          @text_view = text_view :text  => 'What hath Matz wrought?', :id => 42, :text_size => 48.0,
                                 :width => :fill_parent, :gravity => android.view.Gravity::CENTER
        end
  end

  def on_create_options_menu(menu)
    mi = menu.add('Test')
    # mi.icon = $package.R::drawable::get_ruboto_core
    mi.setIcon($package.R::drawable::get_ruboto_core)
    mi.set_on_menu_item_click_listener do |menu_item|
      @text_view.text = 'What hath Matz wrought!'
      toast 'Flipped a bit via butterfly'
    end
    true
  end
end
