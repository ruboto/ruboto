require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :TextView

class PaddingActivity
  def onCreate(bundle)
    super
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').
        map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    self.content_view = linear_layout id: 41, padding: [10, 20, 30, 40] do
      text_view text: 'Text with padding', id: 42, padding: [1, 2, 4, 8]
    end
  end
end
