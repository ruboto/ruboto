require File.expand_path("ruboto_gen_test", File.dirname(__FILE__))

if not RubotoTest::ON_JRUBY_JARS_1_5_6
  class RubotoGenWithPsychTest < RubotoGenTest
    def setup
      generate_app :with_psych => true
    end

    def test_psych_jar_exists
      assert File.exists?("#{APP_DIR}/libs/psych.jar"), "Failed to generate psych jar"
    end

  end
else
  puts "Skipping Psych tests on jruby-jars-1.5.6"
end
