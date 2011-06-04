require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'

class RubotoUpdateTest < Test::Unit::TestCase
  def setup
    Dir.mkdir TMP_DIR unless File.exists? TMP_DIR
    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
    Dir.chdir TMP_DIR do
      system "tar xzf #{PROJECT_DIR}/examples/RubotoTestApp_0.1.0_jruby_1.6.3.dev.tgz"
    end
  end

  def teardown
    # FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end

  def test_plain_update
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} update app"
      assert_equal 0, $?, "update app failed with return code #$?"
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
