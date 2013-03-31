require File.expand_path("test_helper", File.dirname(__FILE__))

# FIXME(uwe):  Remove check when we stop supporting JRuby older than 1.7.0.rc1
# FIXME(uwe):  Remove check when we stop supporting Android < 4.0.3
if RubotoTest::JRUBY_JARS_VERSION >= Gem::Version.new('1.7.0.rc1') &&
    (RubotoTest::ANDROID_OS >= 15 || RubotoTest::RUBOTO_PLATFORM != 'STANDALONE')

require 'bigdecimal'
require 'test/app_test_methods'

class SqldroidTest < Test::Unit::TestCase
  def setup
    generate_app :bundle => :sqldroid
  end

  def teardown
    cleanup_app
  end

  def test_sqldroid
    Dir.chdir APP_DIR do
      File.open('src/ruboto_test_app_activity.rb', 'w'){|f| f << <<EOF}
require 'ruboto/activity'
require 'ruboto/widget'
require 'sqldroid'

ruboto_import_widgets :LinearLayout, :ListView, :TextView

class MyArrayAdapter < android.widget.ArrayAdapter
  def get_view(position, convert_view, parent)
    puts "IN get_view!!!"
    @inflater ||= context.getSystemService(Context::LAYOUT_INFLATER_SERVICE)
    row = convert_view ? convert_view : @inflater.inflate(mResource, nil)
    row.findViewById(mFieldId).text = get_item(position)
    row
  rescue Exception
    puts "Exception getting list item view: \#$!"
    puts $!.backtrace.join("\n")
    convert_view
  end
end

class RubotoTestAppActivity
  def onCreate(bundle)
    super
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "\#{s[0..0].upcase}\#{s[1..-1]}" }.join(' ')

    adapter = MyArrayAdapter.new(self, android.R.layout.simple_list_item_1 , AndroidIds::text1, ['Record one', 'Record two'])

    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL do
          @text_view_margins = text_view :text => 'What hath Matz wrought?', :id => 42
          @list_view = list_view :adapter => adapter, :id => 43
        end
  end
end
EOF

      File.open('test/src/ruboto_test_app_activity_test.rb', 'w'){|f| f << <<EOF}
activity Java::org.ruboto.test_app.RubotoTestAppActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    @list_view = activity.findViewById(43)
    break if (@text_view && @list_view) || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
  assert @list_view
end

test("activity starts") do |activity|
  assert true
end
EOF

    end

    run_app_tests
  end

end

end
# EMXIF
