require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :ListView, :TextView

class SubclassOfArrayAdapter < Java::AndroidWidget::ArrayAdapter
  def getView(position, convert_view, parent)
    @inflater ||= context.getSystemService(Context::LAYOUT_INFLATER_SERVICE)
    row = convert_view ? convert_view : @inflater.inflate(mResource, nil)
    row.findViewById(mFieldId).text = "[#{get_item(position)}]"
    row
  rescue Exception
    puts "Exception getting list item view: #$!"
    puts $!.backtrace.join("\n")
    convert_view
  end
end

class Java::AndroidWidget::ArrayAdapter
   field_reader :mResource, :mFieldId
end

class SubclassActivity
  def onCreate(bundle)
    super
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    adapter = SubclassOfArrayAdapter.new(self, android.R.layout.simple_list_item_1, android.R.id.text1, ['Record one', 'Record two'])

    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL do
          @text_view = text_view :text => 'What hath Matz wrought?', :id => 42
          @list_view = list_view :adapter => adapter, :id => 43,
              :on_item_click_listener => proc{|_,view,_,_| @text_view.text = view.findViewById(android.R.id.text1).text}
        end
  end
end
