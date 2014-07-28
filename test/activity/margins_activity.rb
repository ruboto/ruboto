require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :TextView

class MarginsActivity
  def onCreate(bundle)
    super
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').
        map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view = linear_layout orientation: :vertical do
      @text_view_margins = text_view text: 'What hath Matz wrought?', id: 42,
          margins: [100, 0, 0, 0]
      @text_view_layout = text_view text: 'What hath Matz wrought?', id: 43,
          layout: {set_margins: [100, 0, 0, 0]}
      @text_view_layout = text_view text: 'What hath Matz wrought?', id: 44,
          layout: {margins: [100, 0, 0, 0]}
      @text_view_fieldset = text_view text: 'What hath Matz wrought?', id: 45,
          layout: {left_margin: 100}
    end
  end
end
