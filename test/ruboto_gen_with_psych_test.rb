require File.expand_path("ruboto_gen_test", File.dirname(__FILE__))

if not RubotoTest::ON_JRUBY_JARS_1_5_6
  class RubotoGenWithPsychTest < RubotoGenTest
    def setup
      generate_app :with_psych => true
    end

    def test_psych_jar_exists
      assert File.exists?("#{APP_DIR}/libs/psych.jar"), "Failed to generate psych jar"
    end

    def test_new_apk_size_is_within_limits
      apk_size = BigDecimal(File.size("#{APP_DIR}/bin/RubotoTestApp-debug.apk").to_s) / 1024
      upper_limit = 4900.0
      lower_limit = upper_limit * 0.9
      assert apk_size <= upper_limit, "APK was larger than #{'%.1f' % upper_limit}KB: #{'%.1f' % apk_size.ceil(1)}KB"
      assert apk_size >= lower_limit, "APK was smaller than #{'%.1f' % lower_limit}KB: #{'%.1f' % apk_size.ceil(1)}KB.  You should lower the limit."
    end

  end
else
  puts "Skipping Psych tests on jruby-jars-1.5.6"
end
