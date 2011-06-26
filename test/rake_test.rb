require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'

$stdout.sync = true

class RakeTest < Test::Unit::TestCase
  def setup
    generate_app
  end

  def teardown
    # FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end

  def test_that_update_scripts_task_copies_files_to_sdcard_if_permissions_are_set
    manifest = File.read("#{APP_DIR}/AndroidManifest.xml")
    manifest.gsub! %r{</manifest>}, %Q{ <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />\n</manifest>}
    File.open("#{APP_DIR}/AndroidManifest.xml", 'w') { |f| f << manifest }

    Dir.chdir APP_DIR do
      system 'rake install:restart:clean'
      assert_equal 0, $?
    end

    # wait_for_dir("/mnt/sdcard/Android/data/#{PACKAGE}/files/scripts")
    wait_for_dir("/sdcard/Android/data/#{PACKAGE}/files/scripts")
  end

  unless ANDROID_TARGET == 'android-7'
    def test_that_update_scripts_task_copies_files_to_app_directory_when_permissions_are_not_set
      Dir.chdir APP_DIR do
        system 'rake install:restart:clean'
        assert_equal 0, $?
      end
      wait_for_dir("/data/data/#{PACKAGE}/files/scripts")
    end
  end

  private

  def wait_for_dir(dir)
    puts "Waiting for app to generate script directory: #{dir}"
    start = Time.now
    loop do
      break if `adb shell ls -d #{dir}`.chomp =~ %r{^#{dir}$}
      flunk 'Timeout waiting for scripts directory to appear' if Time.now > start + 60
      sleep 1
    end
  end

end