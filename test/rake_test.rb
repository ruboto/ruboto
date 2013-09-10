require File.expand_path('test_helper', File.dirname(__FILE__))

class RakeTest < Test::Unit::TestCase
  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  def test_that_update_scripts_task_copies_files_to_sdcard_and_are_read_by_activity
    run_app_tests

    Dir.chdir APP_DIR do
      activity_filename = 'src/ruboto_test_app_activity.rb'
      s = File.read(activity_filename)
      s.gsub!(/What hath Matz wrought\?/, 'This text was changed by script!')
      File.open(activity_filename, 'w') { |f| f << s }

      test_filename = 'test/src/ruboto_test_app_activity_test.rb'
      s2 = File.read(test_filename)
      s2.gsub!(/What hath Matz wrought\?/, 'This text was changed by script!')
      File.open(test_filename, 'w') { |f| f << s2 }

      apk_timestamp = File.ctime("bin/#{APP_NAME}-debug.apk")
    end

    # FIXME(uwe): Uncomment this when we can build the test package without building the main package
    # assert_equal apk_timestamp, File.ctime("bin/#{APP_NAME}-debug.apk"), 'APK should not have been rebuilt'
    # EMXIF

    assert_match %r{^/sdcard/Android/data/#{PACKAGE}/files/scripts$}, `adb shell ls -d /sdcard/Android/data/#{PACKAGE}/files/scripts`.chomp
  end

  def test_that_apk_is_built_if_only_one_ruby_source_file_has_changed
    Dir.chdir APP_DIR do
      system 'rake debug'
      apk_timestamp = File.ctime("bin/#{APP_NAME}-debug.apk")
      FileUtils.touch 'src/ruboto_test_app_activity.rb'
      system 'rake debug'
      assert_not_equal apk_timestamp, File.ctime("bin/#{APP_NAME}-debug.apk"), 'APK should have been rebuilt'
    end
  end

  def test_that_manifest_is_updated_when_project_properties_are_changed
    Dir.chdir APP_DIR do
      manifest = File.read('AndroidManifest.xml')
      assert_equal "android:minSdkVersion='#{ANDROID_TARGET}'", manifest.slice(/android:minSdkVersion='\d+'/)
      assert_equal "android:targetSdkVersion='#{ANDROID_TARGET}'", manifest.slice(/android:targetSdkVersion='\d+'/)
      prop_file = File.read('project.properties')
      File.open('project.properties', 'w') { |f| f << prop_file.sub(/target=android-#{ANDROID_TARGET}/, 'target=android-6') }
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
  end

end
