require File.expand_path("test_helper", File.dirname(__FILE__))

class RakeTest < Test::Unit::TestCase
  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  if ANDROID_OS == 'android-7'
    puts "Skipping sdcard test since files on sdcard are not removed on android-7 on app uninstall"
  else
    def test_that_update_scripts_task_copies_files_to_sdcard_and_are_read_by_activity
      Dir.chdir APP_DIR do
        activity_filename = "src/ruboto_test_app_activity.rb"
        s = File.read(activity_filename)
        s.gsub!(/What hath Matz wrought\?/, "This text was changed by script!")
        File.open(activity_filename, 'w') { |f| f << s }

        test_filename = "test/assets/scripts/ruboto_test_app_activity_test.rb"
        s2 = File.read(test_filename)
        s2.gsub!(/What hath Matz wrought\?/, "This text was changed by script!")
        File.open(test_filename, 'w') { |f| f << s2 }

        apk_timestamp = File.ctime("bin/#{APP_NAME}-debug.apk")
        system 'rake test:quick'
        assert_equal 0, $?

        # FIXME(uwe): Uncomment this when we can build the test package without building the main package
        # assert_equal apk_timestamp, File.ctime("bin/#{APP_NAME}-debug.apk"), 'APK should not have been rebuilt'
        # FIXME end

        assert `adb shell ls -d /sdcard/Android/data/#{PACKAGE}/files/scripts`.chomp =~ %r{^/sdcard/Android/data/#{PACKAGE}/files/scripts$}
      end
    end
  end

end