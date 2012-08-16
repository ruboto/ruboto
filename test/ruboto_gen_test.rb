require File.expand_path("test_helper", File.dirname(__FILE__))
require 'bigdecimal'
require 'test/app_test_methods'

class RubotoGenTest < Test::Unit::TestCase
  include AppTestMethods

  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  def test_icons_are_updated
    Dir.chdir APP_DIR do
      assert_equal 4032, File.size('res/drawable-hdpi/ic_launcher.png')
      assert_equal 2548, File.size('res/drawable-mdpi/ic_launcher.png')
      assert_equal 1748, File.size('res/drawable-ldpi/ic_launcher.png')
    end
  end

  def test_gen_class_activity_with_lowercase_should_fail
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen class activity --name VeryNewActivity"
      assert_equal 1, $?.exitstatus
      assert !File.exists?('src/org/ruboto/test_app/VeryNewActivity.java')
      assert !File.exists?('src/very_new_activity.rb')
      assert !File.exists?('test/src/very_new_activity_test.rb')
      assert File.read('AndroidManifest.xml') !~ /VeryNewActivity/
    end
  end

  def test_new_apk_size_is_within_limits
    apk_size = BigDecimal(File.size("#{APP_DIR}/bin/RubotoTestApp-debug.apk").to_s) / 1024
    version = "  PLATFORM: #{RUBOTO_PLATFORM}"
    version << ", ANDROID_TARGET: #{ANDROID_TARGET}"
    if RUBOTO_PLATFORM == 'STANDALONE'
      upper_limit = {
          '1.6.7' => 5800.0,
          '1.7.0.preview1' => ANDROID_TARGET < 15 ? 7062.0 : 7308.0,
          '1.7.0.preview2' => ANDROID_TARGET < 15 ? 7062.0 : 7308.0,
      }[JRUBY_JARS_VERSION.to_s] || 4200.0
      version << ", JRuby: #{JRUBY_JARS_VERSION.to_s}"
    else
      upper_limit = {
          7 => 62.0,
          10 => 67.0,
          15 => 67.0,
      }[ANDROID_TARGET] || 64.0
    end
    lower_limit = upper_limit * 0.9
    assert apk_size <= upper_limit, "APK was larger than #{'%.1f' % upper_limit}KB: #{'%.1f' % apk_size.ceil(1)}KB.#{version}"
    assert apk_size >= lower_limit, "APK was smaller than #{'%.1f' % lower_limit}KB: #{'%.1f' % apk_size.floor(1)}KB.  You should lower the limit.#{version}"
  end

  def test_gen_subclass
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen subclass android.database.sqlite.SQLiteOpenHelper --name MyDatabaseHelper --method_base on"
      assert_equal 0, $?.exitstatus
      assert File.exists?('src/org/ruboto/test_app/MyDatabaseHelper.java')
      # FIXME(uwe):  Add tests and definition script?
      # assert File.exists?('src/my_database_helper.rb')
      # assert File.exists?('test/src/my_database_helper_test.rb')
      system 'rake debug'
      assert_equal 0, $?
    end
  end

  def test_gen_interface
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen interface java.lang.Runnable --name MyRunnable"
      assert_equal 0, $?.exitstatus
      java_source_file = 'src/org/ruboto/test_app/MyRunnable.java'
      assert File.exists?(java_source_file)
      # FIXME(uwe):  Add tests and definition script?
      # assert File.exists?('src/my_runnable.rb')
      # assert File.exists?('test/src/my_runnable_test.rb')

      java_source = File.read(java_source_file)
      File.open(java_source_file, 'w'){|f| f << java_source.gsub(/^\}\n/, "    public static void main(String[] args){new MyRunnable().run();}\n}\n")}

      system 'rake debug'
      assert_equal 0, $?

      File.open('src/org/ruboto/JRubyAdapter.java', 'w'){|f| f << <<EOF}
package org.ruboto;
public class JRubyAdapter {
    public static Object get(String varName){return null;}
    public static boolean isInitialized(){return true;}
    public static boolean isJRubyOneSeven(){return true;}
    public static boolean isJRubyPreOneSeven(){return false;}
    public static void put(String varName, Object value){}
    public static void runRubyMethod(Object receiver, String method){}
    public static boolean runScriptlet(String scriptlet){return false;}
}
EOF
      system 'javac -cp bin/classes -d bin/classes src/org/ruboto/JRubyAdapter.java'
      assert_equal 0, $?
      system 'javac -cp bin/classes -d bin/classes src/org/ruboto/test_app/MyRunnable.java'
      assert_equal 0, $?
      system 'java -cp bin/classes org.ruboto.test_app.MyRunnable'
      assert_equal 0, $?
    end
  end

  def test_gen_jruby
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen jruby"
      assert_equal 0, $?.exitstatus
      assert File.exists?("libs/jruby-core-#{JRUBY_JARS_VERSION}.jar")
      assert File.exists?("libs/jruby-stdlib-#{JRUBY_JARS_VERSION}.jar")
    end
  end

end
