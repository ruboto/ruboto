require File.expand_path('test_helper', File.dirname(__FILE__))
require_relative '../assets/rakelib/ruboto.device'

class RakeTest < Minitest::Test
  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  def test_that_update_scripts_task_copies_files_to_sdcard_and_are_read_by_activity
    Dir.chdir APP_DIR do
      activity_filename = 'src/ruboto_test_app_activity.rb'
      s = File.read(activity_filename)
      s.gsub!(/What hath Matz wrought\?/, 'This text was changed by script!')
      File.open(activity_filename, 'w') { |f| f << s }

      test_filename = 'test/src/ruboto_test_app_activity_test.rb'
      s2 = File.read(test_filename)
      s2.gsub!(/What hath Matz wrought\?/, 'This text was changed by script!')
      File.open(test_filename, 'w') { |f| f << s2 }
    end
    run_app_tests

    # FIXME(uwe): Uncomment this when we can build the test package without building the main package
    # assert_equal apk_timestamp, File.mtime("bin/#{APP_NAME}-debug.apk"), 'APK should not have been rebuilt'
    # EMXIF

    assert_match %r{^#{scripts_path(PACKAGE)}$}, `adb shell ls -d #{scripts_path(PACKAGE)}`.chomp
  end

  def test_that_apk_is_not_built_if_nothing_has_changed
    Dir.chdir APP_DIR do
      apk_timestamp = apk_mtime
      system 'rake debug'
      assert apk_timestamp == apk_mtime, 'APK should not have been rebuilt'
    end
  end

  # FIXME(uwe):  This is actually a case where we want to just update the Ruby
  # source file instead of rebuilding the apk.
  def test_that_apk_is_built_if_only_one_ruby_source_file_has_changed
    Dir.chdir APP_DIR do
      apk_timestamp = apk_mtime
      FileUtils.touch 'src/ruboto_test_app_activity.rb', mtime: apk_timestamp + 1
      system 'rake debug'
      assert apk_timestamp != apk_mtime, 'APK should have been rebuilt'
    end
  end

  def test_that_apk_is_built_if_only_one_non_ruby_source_file_has_changed
    Dir.chdir APP_DIR do
      apk_timestamp = apk_mtime
      FileUtils.touch 'src/not_ruby_source.properties', mtime: apk_timestamp + 1
      system 'rake debug'
      assert apk_timestamp != apk_mtime,
          'APK should have been rebuilt'
    end
  end

  def test_that_manifest_is_updated_when_project_properties_are_changed
    Dir.chdir APP_DIR do
      manifest = File.read('AndroidManifest.xml')
      assert_equal "android:minSdkVersion='#{ANDROID_TARGET}'", manifest[/android:minSdkVersion='[^']+'/]
      assert_equal "android:targetSdkVersion='#{ANDROID_TARGET}'", manifest[/android:targetSdkVersion='[^']+'/]
      write_project_properties(6)
      system 'rake debug'
      manifest = File.read('AndroidManifest.xml')
      assert_equal "android:minSdkVersion='6'", manifest.slice(/android:minSdkVersion='\d+'/)
      assert_equal "android:targetSdkVersion='6'", manifest.slice(/android:targetSdkVersion='\d+'/)
    end
  end

  def test_install_with_space_in_project_name
    app_dir = "#{APP_DIR} with_space"
    FileUtils.mv APP_DIR, app_dir
    Dir.chdir app_dir do
      system 'rake install'
      raise "'rake install' exited with code #$?" unless $? == 0
    end
  ensure
    FileUtils.rm_rf app_dir
  end

  def test_install_when_adb_server_is_stopped
    Dir.chdir APP_DIR do
      system 'adb kill-server'
      system 'rake install'
      raise "'rake install' exited with code #$?" unless $? == 0
    end
    system 'adb logcat >> adb_logcat.log&' if File.exists?('adb_logcat.log')
  end

  private

  def apk_mtime
    File.mtime("bin/#{APP_NAME}-debug.apk")
  end

end
