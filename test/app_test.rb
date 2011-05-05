require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'

class AppTest < Test::Unit::TestCase
  PACKAGE ='org.ruboto.test_app'
  APP_NAME = 'RubotoTestApp'
  TMP_DIR = File.join PROJECT_DIR, 'tmp'
  APP_DIR = File.join PROJECT_DIR, 'tmp', APP_NAME

  def setup
    Dir.mkdir TMP_DIR unless File.exists? TMP_DIR
    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
    system "jruby -rubygems -I #{PROJECT_DIR}/lib #{PROJECT_DIR}/bin/ruboto gen app --package #{PACKAGE} --path #{APP_DIR} --name #{APP_NAME} --target android-8 --min_sdk android-8 --activity #{APP_NAME}Activity"
    raise "gen app failed with return code #$?" unless $? == 0
  end

  def teardown
    # FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end

  def test_that_tests_work_on_new_project
    run_app_tests
  end

  def test_that_yaml_loads
    filename = "#{APP_DIR}/assets/scripts/ruboto_test_app_activity.rb"
    s = File.read(filename)
    s.gsub!(/(require 'ruboto.rb')/, "\\1\nrequire 'yaml'")
    File.open(filename, 'w'){|f| f << s}
    run_app_tests
  end

  private

  def run_app_tests
    Dir.chdir "#{APP_DIR}/test" do
      system "adb uninstall #{PACKAGE}"
      system 'ant run-tests'
      raise "tests failed with return code #$?" unless $? == 0
      system "adb uninstall #{PACKAGE}"
    end
  end

end