require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'

class RubotoGenTest < Test::Unit::TestCase
  def setup
    Dir.mkdir TMP_DIR unless File.exists? TMP_DIR
    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end

  def teardown
    # FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end

  def test_plain_gen
    generate_app
    assert_equal 0, $?, "gen app failed with return code #$?"
  end

  if not ON_JRUBY_JARS_1_5_6
    def test_gen_with_psych
      generate_app :with_psych => true
      assert_equal 0, $?, "gen app failed with return code #$?"
      assert File.exists?("#{APP_DIR}/libs/psych.jar"), "Failed to generate psych jar"
    end
  else
    puts "Skipping Psych tests on jruby-jars-1.5.6"
  end

end
