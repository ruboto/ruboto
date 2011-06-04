require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'

$stdout.sync = true

class RakeTest < Test::Unit::TestCase
  def setup
    Dir.mkdir TMP_DIR unless File.exists? TMP_DIR
    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
    generate_app
    raise "gen app failed with return code #$?" unless $? == 0
  end

  def teardown
    # FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end

  def test_that_update_scripts_task_copies_files_to_sdcard_if_permissions_are_set
    manifest = File.read("#{APP_DIR}/AndroidManifest.xml")
    manifest.gsub! %r{</manifest>}, %Q{ <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />\n</manifest>}
    File.open("#{APP_DIR}/AndroidManifest.xml", 'w'){|f| f << manifest}

    Dir.chdir APP_DIR do
      system 'rake install:restart:clean'
      assert_equal 0, $?
    end

    puts 'Waiting for app to generate script directory'
    start = Time.now
    loop do
      break if `adb shell ls -d /mnt/sdcard/Android/data/#{PACKAGE}/files/scripts`.chomp =~ %r{^/mnt/sdcard/Android/data/#{PACKAGE}/files/scripts$}
      flunk 'Timeout waiting for scripts directory to appear' if Time.now > start + 60
      sleep 1
    end
  end

  def test_that_update_scripts_task_copies_files_to_app_directory_when_permissions_are_not_set
    Dir.chdir APP_DIR do
      system 'rake install:restart:clean'
      assert_equal 0, $?
    end

    puts 'Waiting for app to generate script directory'
    start = Time.now
    loop do
      break if `adb shell ls -d /data/data/#{PACKAGE}/files/scripts`.chomp =~ %r{^/data/data/#{PACKAGE}/files/scripts$}
      flunk 'Timeout waiting for scripts directory to appear' if Time.now > start + 60
      sleep 1
    end
  end

end