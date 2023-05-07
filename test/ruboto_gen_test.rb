require File.expand_path('test_helper', File.dirname(__FILE__))
require 'bigdecimal'
require 'test/app_test_methods'

class RubotoGenTest < Minitest::Test
  include AppTestMethods

  def setup
    generate_app heap_alloc: 50
  end

  def teardown
    cleanup_app
  end

  def test_gitignore_is_included_in_new_project
    Dir.chdir APP_DIR do
      assert File.exist? '.gitignore'
    end
  end

  def test_icons_are_updated
    Dir.chdir APP_DIR do
      assert_equal 3834, File.size('res/drawable-hdpi/ic_launcher.png')
      assert_equal 2513, File.size('res/drawable-mdpi/ic_launcher.png')
      assert_equal 1689, File.size('res/drawable-ldpi/ic_launcher.png')
    end
  end

  def test_activity_with_number_in_name
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen class Activity --name App1Activity"
      assert_equal 0, $?.exitstatus
      assert File.exist?('src/org/ruboto/test_app/App1Activity.java')
      assert File.exist?('src/app1_activity.rb')
      assert File.exist?('test/src/app1_activity_test.rb')
    end
    run_app_tests
  end

  def test_gen_class_activity_with_lowercase_should_fail
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen class activity --name VeryNewActivity"
      assert_equal 1, $?.exitstatus
      assert !File.exist?('src/org/ruboto/test_app/VeryNewActivity.java')
      assert !File.exist?('src/very_new_activity.rb')
      assert !File.exist?('test/src/very_new_activity_test.rb')
      assert File.read('AndroidManifest.xml') !~ /VeryNewActivity/
    end
  end

  # APK was    66.3KB.  PLATFORM: CURRENT, ANDROID_TARGET: 10
  # APK was    66.6KB.  PLATFORM: CURRENT, ANDROID_TARGET: 15
  # APK was    74.9KB.  PLATFORM: CURRENT, ANDROID_TARGET: 16
  # APK was    80.4KB.  PLATFORM: CURRENT, ANDROID_TARGET: 19
  # APK was    75.1KB.  PLATFORM: CURRENT, ANDROID_TARGET: 22
  # APK was    65.0KB.  PLATFORM: FROM_GEM, ANDROID_TARGET: 10
  # APK was    81.0KB.  PLATFORM: FROM_GEM, ANDROID_TARGET: 16
  # APK was    80.2KB.  PLATFORM: FROM_GEM, ANDROID_TARGET: 17
  # APK was  8428.4KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 10, JRuby: 1.7.4
  # APK was  7405.8KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 15, JRuby: 1.7.4
  # APK was  7420.9KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 16, JRuby: 1.7.4
  # APK was  8755.5KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 15, JRuby: 1.7.5
  # APK was  8770.2KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 16, JRuby: 1.7.5
  # APK was  8766.1KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 16, JRuby: 1.7.6
  # APK was  8781.6KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 16, JRuby: 1.7.8
  # APK was  8789.6KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 16, JRuby: 1.7.9
  # APK was  8791.2KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 16, JRuby: 1.7.10
  # APK was  8575.0KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 10, JRuby: 1.7.11
  # APK was  8793.4KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 16, JRuby: 1.7.11
  # APK was  9743.3KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 16, JRuby: 1.7.12
  # APK was  9123.8KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 19, JRuby: 1.7.12
  # APK was  7574.2KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 19, JRuby: 1.7.13
  # APK was  9745.0KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 19, JRuby: 1.7.14
  # APK was  7587.8KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 19, JRuby: 1.7.15
  # APK was  9985.8KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 19, JRuby: 1.7.17
  # APK was 10052.1KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 17, JRuby: 1.7.18
  # APK was 10045.2KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 19, JRuby: 1.7.18
  # APK was  6721.6KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 15, JRuby: 1.7.19
  # APK was  7882.1KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 19, JRuby: 1.7.19
  # APK was 10109.9KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 21, JRuby: 1.7.19
  # APK was  7040.6KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 15, JRuby: 1.7.20
  # APK was  8938.8KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 19, JRuby: 1.7.20
  # APK was  6999.2KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 15, JRuby: 1.7.22
  # APK was  8501.5KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 23, JRuby: 1.7.22
  # APK was  7006.1KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 15, JRuby: 1.7.23
  # APK was  7083.4KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 15, JRuby: 1.7.24
  # APK was  8596.6KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 19, JRuby: 1.7.24
  # APK was  7081.8KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 15, JRuby: 1.7.25
  # APK was  8730.8KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 19, JRuby: 1.7.25
  # APK was  4633.2KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 22, JRuby: 9.0.0.0.SNAPSHOT
  # APK was  8762.6KB.  PLATFORM: STANDALONE, ANDROID_TARGET: 23, JRuby: 9.0.5.0.SNAPSHOT
  LIMITS = {
      '~>9.1.9.0.SNAPSHOT' => ANDROID_TARGET <= 15 ? 7200 : 9800.0,
      '~>1.7.24' => ANDROID_TARGET <= 15 ? 7200 : 9000.0,
      '~>1.7.22' => ANDROID_TARGET <= 15 ? 7200 : 9000.0,
      '1.7.20' => ANDROID_TARGET <= 15 ? 8000 : 9000.0,
      '1.7.19' => 8000.0,
      '1.7.18' => 10100.0,
      '1.7.17' => 9999.0,
      '1.7.15' => 8000.0,
      '1.7.14' => 9800.0,
      '1.7.13' => 8000.0,
      '1.7.12' => 9800.0,
      '~>1.7.5' => 8800.0,
      '1.7.4' => 8500.0,
  }

  def test_new_apk_size_is_within_limits
    apk_size = BigDecimal(File.size("#{APP_DIR}/bin/RubotoTestApp-debug.apk").to_s) / 1024
    version_string = "  PLATFORM: #{RUBOTO_PLATFORM}"
    version_string << ", ANDROID_TARGET: #{ANDROID_TARGET}"
    if RUBOTO_PLATFORM == 'STANDALONE'
      upper_limit = LIMITS.each do |version_spec, value|
        break value if Gem::Requirement.new(version_spec) =~ JRUBY_JARS_VERSION
      end
      raise "Unknown JRuby version: #{JRUBY_JARS_VERSION}" if upper_limit == LIMITS
      version_string << ", JRuby: #{JRUBY_JARS_VERSION.to_s}"
    else
      upper_limit = {
          10 => 67.0,
          15 => 67.0,
          16 => 82.0,
          17 => 81.0,
          19 => 81.0,
          22 => 76.0,
      }[ANDROID_TARGET] || 76.0
    end
    lower_limit = upper_limit * 0.8
    assert apk_size <= upper_limit, "APK was larger than #{'%.1f' % upper_limit}KB: #{'%.1f' % apk_size.ceil(1)}KB.#{version_string}"
    assert apk_size >= lower_limit, "APK was smaller than #{'%.1f' % lower_limit}KB: #{'%.1f' % apk_size.floor(1)}KB.  You should lower the limit.#{version_string}"
  end

  def test_gen_subclass
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen subclass android.database.sqlite.SQLiteOpenHelper --name MyDatabaseHelper --method_base on"
      assert_equal 0, $?.exitstatus
      assert File.exist?('src/org/ruboto/test_app/MyDatabaseHelper.java')
      assert File.exist?('src/my_database_helper.rb')
      assert File.exist?('test/src/my_database_helper_test.rb')
      system 'rake debug'
      assert_equal 0, $?
    end
  end

  def test_gen_subclass_of_array_adapter
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen subclass android.widget.ArrayAdapter --name RubotoArrayAdapter --method_base all"
      assert_equal 0, $?.exitstatus
      java_source_file = 'src/org/ruboto/test_app/RubotoArrayAdapter.java'
      assert File.exist?(java_source_file)

      # FIXME(uwe):  Workaround for Ruboto Issue #246
      java_source = File.read(java_source_file)
      File.open(java_source_file, 'w') { |f| f << java_source.gsub(/^(public class .*ArrayAdapter) (.*ArrayAdapter)/, '\1<T> \2<T>').gsub(/T.class/, 'Object.class') }
      # EMXIF

      assert File.exist?('src/ruboto_array_adapter.rb')
      assert File.exist?('test/src/ruboto_array_adapter_test.rb')

      File.open('src/ruboto_test_app_activity.rb', 'w') { |f| f << <<EOF }
require 'ruboto/activity'
require 'ruboto/util/stack'
require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :ListView, :TextView

class RubotoTestAppActivity
  def onCreate(bundle)
    super
    set_title 'ListView Example'

    records = [{:text1 => 'First row'}, {:image => resources.get_drawable($package.R::drawable::get_ruboto_core), :text1 => 'Second row'}, 'Third row']
    adapter = $package.RubotoArrayAdapter.new(self, $package.R::layout::list_item, android.R.id.text1, records)
puts "adapter: \#{adapter.inspect}"
    self.content_view =
        linear_layout :orientation => :vertical do
          @text_view = text_view :text => 'What hath Matz wrought?', :id => 42, 
                    :layout => {:width => :match_parent},
                    :gravity => :center, :text_size => 48.0
          list_view :adapter => adapter, :id => 43,
                    :on_item_click_listener => proc{|parent, view, position, id| @text_view.text = 'List item clicked!'}
        end
  end
end
EOF

      File.open('test/src/ruboto_test_app_activity_test.rb', 'w') { |f| f << <<EOF }
activity Java::org.ruboto.test_app.RubotoTestAppActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    @list_view = activity.findViewById(43)
    break if (@text_view && @list_view && @list_view.adapter) || (Time.now - start > 60)
puts "Waiting for adapter: \#{@list_view && @list_view.adapter.inspect}"
    sleep 1
  end
  assert @text_view
  assert @list_view
  assert @list_view.adapter
end

test('Item click changes text') do |activity|
  text_view = activity.findViewById(42)
  list_view = activity.findViewById(43)
  list_view.perform_item_click(list_view.adapter.get_view(1, nil, nil), 1, 1)
  assert_equal 'List item clicked!', text_view.text
end
EOF

      File.open('src/ruboto_array_adapter.rb', 'w') { |f| f << <<EOF }
class Java::AndroidWidget::ArrayAdapter
   field_reader :mResource, :mFieldId
end

class RubotoArrayAdapter
  import android.content.Context

  def getView(position, convert_view, parent)
    @inflater = context.getSystemService(Context::LAYOUT_INFLATER_SERVICE) unless @inflater
    if convert_view
      row = convert_view
      row.findViewById(Ruboto::Id.image).image_drawable = nil
      row.findViewById(android.R.id.text1).text = nil
    else
      row = @inflater.inflate(mResource, nil)
    end

    model = get_item position
    case model
    when Hash
      model.each do |field, value|
        begin
          field_id = Ruboto::Id.respond_to?(field) && Ruboto::Id.send(field) ||
              android.R.id.respond_to?(field) && android.R.id.send(field)
          field_view = row.findViewById(field_id)
          case value
          when String
            field_view.text = value
          when android.graphics.drawable.Drawable
            field_view.image_drawable = value
          else
            raise "Unknown View type: \#{value.inspect}"
          end
        rescue Exception
          puts "Exception setting list item value: \#$!"
          puts $!.backtrace.join("\n")
        end
      end
    else
      row.findViewById(mFieldId).text = model.to_s
    end

    row
  rescue Exception
    puts "Exception getting list item view: \#$!"
    puts $!.backtrace.join("\n")
    convert_view
  end

end
EOF

      File.open('res/layout/list_item.xml', 'w') { |f| f << <<EOF }
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout
        xmlns:android="http://schemas.android.com/apk/res/android"
        android:orientation="horizontal"
        android:layout_width="fill_parent"
        android:layout_height="wrap_content"
        android:background="#ffffff"
>
  <TextView
          android:id="@android:id/text1"
          android:textAppearance="?android:attr/textAppearanceLarge"
          android:gravity="left"
          android:layout_weight="1"
          android:layout_width="wrap_content"
          android:layout_height="?android:attr/listPreferredItemHeight"
          android:textColor="#000000"
  />
  <ImageView
          android:id="@+id/image"
          android:gravity="right"
          android:layout_width="wrap_content"
          android:layout_height="wrap_content"
  />
</LinearLayout>
EOF

    end

    run_app_tests
  end

  def test_activity_with_first_letter_lower_case_in_name
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen class Activity --name appActivity"
      assert_equal 0, $?.exitstatus
      assert File.exist?('src/org/ruboto/test_app/AppActivity.java')
      assert File.exist?('src/app_activity.rb')
      assert File.exist?('test/src/app_activity_test.rb')
    end
  end

  if RUBOTO_PLATFORM == 'FROM_GEM'
    def test_gen_jruby
      Dir.chdir APP_DIR do
        system "#{RUBOTO_CMD} gen jruby #{JRUBY_JARS_VERSION}"
        assert_equal 0, $?.exitstatus
        assert_equal %W(libs/jruby-core-#{JRUBY_JARS_VERSION.to_s.downcase}.jar), Dir['libs/jruby-core-*.jar'].map(&:downcase)
        assert_equal %W(libs/jruby-stdlib-#{JRUBY_JARS_VERSION.to_s.downcase}.jar), Dir['libs/jruby-stdlib-*.jar'].map(&:downcase)
      end
    end
  end

end
