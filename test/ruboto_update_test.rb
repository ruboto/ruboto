require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'
require 'test/app_test'

class RubotoUpdateTest < Test::Unit::TestCase
  include AppTest
  
  def setup
    Dir.mkdir TMP_DIR unless File.exists? TMP_DIR
    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
    Dir.chdir TMP_DIR do
      system "tar xzf #{PROJECT_DIR}/examples/RubotoTestApp_0.1.0_jruby_1.6.3.dev.tgz"
    end
    if ENV['ANDROID_HOME']
      android_home = ENV['ANDROID_HOME']
    else
      android_home = File.dirname(File.dirname(`which adb`))
    end
    File.open("#{APP_DIR}/local.properties", 'w'){|f| f.puts "sdk.dir=#{android_home}"}
  end

  def teardown
    # FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end

  def test_plain_update
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} update app"
      assert_equal 0, $?, "update app failed with return code #$?"
      assert File.readlines('test/build.properties').grep(/\w/).uniq!.nil?, 'Duplicate lines in build.properties'
      assert_equal 1, File.readlines('test/build.xml').grep(/<macrodef name="run-tests-helper">/).size, 'Duplicate macro in build.xml'
      
    end
  end

  if not ON_JRUBY_JARS_1_5_6
    def test_update_with_psych
      Dir.chdir APP_DIR do
        FileUtils.touch "libs/psych.jar"
        system "#{RUBOTO_CMD} update app"
        assert_equal 0, $?, "update app failed with return code #$?"
        assert File.exists?("#{APP_DIR}/libs/psych.jar"), "Failed to generate psych jar"
      end
    end
  else
    puts "Skipping Psych tests on jruby-jars-1.5.6"
  end

end
