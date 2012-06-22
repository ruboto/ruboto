require 'ruboto/activity'

ruboto_import_widgets :ImageButton, :LinearLayout, :TextView

class ImageButtonActivity
  include Ruboto::Activity
  def on_create(bundle)
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    click_handler = proc do |view|
      @text_view.setText 'What hath Matz wrought!'
      toast 'Flipped a bit via butterfly'
    end

    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL do
          @text_view = text_view :text => 'What hath Matz wrought?', :id => 42
          image_button :image_resource    => $package.R::drawable::get_ruboto_core, :width => :wrap_content, :id => 43,
                       :on_click_listener => click_handler
        end
  end
end
