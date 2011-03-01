require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'

class RubotoRbTest < Test::Unit::TestCase
  APP_NAME = 'RubotoSampleApp'
  TMP_DIR  = File.join PROJECT_DIR, 'tmp'
  APP_DIR  = File.join PROJECT_DIR, 'tmp', APP_NAME

  def setup
    Dir.mkdir TMP_DIR unless File.exists? TMP_DIR
    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
    system "jruby #{PROJECT_DIR}/bin/ruboto gen app --package org.ruboto.sample_app --path #{APP_DIR} --name #{APP_NAME} --target android-8 --min_sdk android-8 --activity #{APP_NAME}Activity"
    raise "gen app failed with return code #$?" unless $? == 0
  end

  def teardown
    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end

  def test_that_tests_work_on_new_project
    Dir.chdir "#{APP_DIR}/test" do
      system 'ant run-tests'
      raise "installation failed with return code #$?" unless $? == 0
    end
  end
end