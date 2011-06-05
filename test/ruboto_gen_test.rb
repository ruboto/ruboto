require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'

class RubotoGenTest < Test::Unit::TestCase
  def test_plain_gen
    generate_app
  end

  if not ON_JRUBY_JARS_1_5_6
    def test_gen_with_psych
      generate_app :with_psych => true
      assert File.exists?("#{APP_DIR}/libs/psych.jar"), "Failed to generate psych jar"
    end
  else
    puts "Skipping Psych tests on jruby-jars-1.5.6"
  end

end
