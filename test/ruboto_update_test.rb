require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'
require 'test/app_test_methods'

module UpdateTestMethods
  include RubotoTest

  def setup(with_psych = false)
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
    File.open("#{APP_DIR}/test/local.properties", 'w'){|f| f.puts "sdk.dir=#{android_home}"}
    Dir.chdir APP_DIR do
      FileUtils.touch "libs/psych.jar" if with_psych
      system "#{RUBOTO_CMD} update app"
      assert_equal 0, $?, "update app failed with return code #$?"
    end
  end

  def teardown
    cleanup_app
  end
  
  def test_properties_and_ant_file_has_no_duplicates
    Dir.chdir APP_DIR do
      assert File.readlines('test/build.properties').grep(/\w/).uniq!.nil?, 'Duplicate lines in build.properties'
      assert_equal 1, File.readlines('test/build.xml').grep(/<macrodef name="run-tests-helper">/).size, 'Duplicate macro in build.xml'
    end
  end
end

class RubotoUpdateTest < Test::Unit::TestCase
  include UpdateTestMethods
  include AppTestMethods
end

if not RubotoTest::ON_JRUBY_JARS_1_5_6
  class RubotoUpdateWithPsychTest < Test::Unit::TestCase
    include UpdateTestMethods
    include AppTestMethods

    def setup
      super(true)
    end
    
    def test_psych_jar_exists
      assert File.exists?("#{APP_DIR}/libs/psych.jar"), "Failed to generate psych jar"
    end
  
  end
else
  puts "Skipping Psych tests on jruby-jars-1.5.6"
end
