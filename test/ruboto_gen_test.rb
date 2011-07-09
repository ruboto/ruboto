require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'
require 'test/app_test_methods'

class RubotoGenTest < Test::Unit::TestCase
  include AppTestMethods

  def setup
    Dir.mkdir TMP_DIR unless File.exists? TMP_DIR
    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
    generate_app
  end

  def teardown
    # FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end
end

if not RubotoTest::ON_JRUBY_JARS_1_5_6
  class RubotoGenWithPsychTest < Test::Unit::TestCase
    include AppTestMethods
    
    def setup
      Dir.mkdir TMP_DIR unless File.exists? TMP_DIR
      FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
      generate_app :with_psych => true
    end

    def teardown
      # FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
    end

    def test_psych_jar_exists
      assert File.exists?("#{APP_DIR}/libs/psych.jar"), "Failed to generate psych jar"
    end

  end
else
  puts "Skipping Psych tests on jruby-jars-1.5.6"
end
