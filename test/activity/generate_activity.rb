require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/generate'

ruboto_import_widgets :LinearLayout, :ListView, :TextView

ruboto_generate("android.widget.ArrayAdapter" => $package_name + ".MyArrayAdapter")

class GenerateActivity
  def on_create(bundle)
    super
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')

    adapter = MyArrayAdapter.new(self, android.R.layout.simple_list_item_1 , AndroidIds::text1, ['Record one', 'Record two'])
    adapter.initialize_ruboto_callbacks do
      def get_view(position, convert_view, parent)
        puts "IN get_view!!!"
        @inflater ||= context.getSystemService(Context::LAYOUT_INFLATER_SERVICE)
        row = convert_view ? convert_view : @inflater.inflate(mResource, nil)
        row.findViewById(mFieldId).text = get_item(position)
        row
      rescue Exception
        puts "Exception getting list item view: #$!"
        puts $!.backtrace.join("\n")
        convert_view
      end
    end

    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL do
          @text_view_margins = text_view :text => 'What hath Matz wrought?', :id => 42
          @list_view = list_view :adapter => adapter, :id => 43
        end
  end
end
