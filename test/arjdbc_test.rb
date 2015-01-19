require File.expand_path('test_helper', File.dirname(__FILE__))

# FIXME(uwe):  Remove check when we stop supporting Android < 4.0.3
if RubotoTest::ANDROID_OS >= 15

class ArjdbcTest < Minitest::Test
  def setup
    generate_app :bundle => [['activerecord', '<4.0.0'], 'activerecord-jdbcsqlite3-adapter', :sqldroid]
  end

  def teardown
    cleanup_app
  end

  def test_arjdbc
    Dir.chdir APP_DIR do
      File.open('src/ruboto_test_app_activity.rb', 'w'){|f| f << <<EOF}
require 'ruboto/widget'
require 'ruboto/util/stack'
with_large_stack do
  require 'active_record'
end

ruboto_import_widgets :LinearLayout, :ListView, :TextView

class MyArrayAdapter < android.widget.ArrayAdapter
  def get_view(position, convert_view, parent)
    @inflater ||= context.getSystemService(Context::LAYOUT_INFLATER_SERVICE)
    row = convert_view ? convert_view : @inflater.inflate(mResource, nil)
    row.findViewById(mFieldId).text = get_item(position)
    row
  rescue Exception
    puts "Exception getting list item view: \#$!"
    puts $!.backtrace.join("\\n")
    convert_view
  end
end

class RubotoTestAppActivity
  def onCreate(bundle)
    super
    setTitle File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "\#{s[0..0].upcase}\#{s[1..-1]}" }.join(' ')

    @adapter = MyArrayAdapter.new(self, android.R.layout.simple_list_item_1 , android.R.id.text1, [])

    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL do
          @text_view_margins = text_view :text => 'What hath Matz wrought?', :id => 42
          @list_view = list_view :adapter => @adapter, :id => 43
        end
  end

  def onResume
    super

    db_dir = "\#{application_context.files_dir}/sqlite"

    with_large_stack do

      ActiveRecord::Base.establish_connection(
        :adapter => 'jdbc',
        :driver => 'org.sqldroid.SQLDroidDriver',
        :url => "jdbc:sqldroid:\#{db_dir}?timeout=60000&retry=1000",
        :database => db_dir,
      )

      begin
        ActiveRecord::Base.connection.execute "DROP TABLE companions"
      rescue ActiveRecord::StatementInvalid
        # Table does not exist
      end
      ActiveRecord::Base.connection.execute "CREATE TABLE companions (id INTEGER PRIMARY KEY, name VARCHAR(20) NOT NULL)"
      ActiveRecord::Base.connection.execute "INSERT INTO companions VALUES (1, 'Frodo')"
      ActiveRecord::Base.connection.execute "INSERT INTO companions VALUES (2, 'Samwise')"
      ActiveRecord::Base.connection.execute "INSERT INTO companions VALUES (3, 'Meriadoc')"
      ActiveRecord::Base.connection.execute "INSERT INTO companions VALUES (4, 'Peregrin')"
      ActiveRecord::Base.connection.execute "INSERT INTO companions VALUES (5, 'Gandalf')"
      ActiveRecord::Base.connection.execute "INSERT INTO companions VALUES (6, 'Legolas')"
      ActiveRecord::Base.connection.execute "INSERT INTO companions VALUES (7, 'Gimli')"
      ActiveRecord::Base.connection.execute "INSERT INTO companions VALUES (8, 'Aragorn')"
      ActiveRecord::Base.connection.execute "INSERT INTO companions VALUES (9, 'Boromir')"
      companions = ActiveRecord::Base.connection.execute "SELECT name FROM companions"
      run_on_ui_thread { @adapter.add_all companions }
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
