require File.expand_path('test_helper', File.dirname(__FILE__))

if RubotoTest::RUBOTO_PLATFORM == 'STANDALONE'
  require 'bigdecimal'

  class MinimalAppTest < Test::Unit::TestCase
    def setup
      generate_app :included_stdlibs => []
    end

    def teardown
      cleanup_app
    end

    # APK was 4.7MB.  JRuby: 1.7.0, ANDROID_TARGET: 15
    # APK was 4.5MB.  JRuby: 1.7.2, ANDROID_TARGET: 10
    # APK was 4.5MB.  JRuby: 1.7.2, ANDROID_TARGET: 15
    # APK was 4.3MB.  JRuby: 1.7.3, ANDROID_TARGET: 10
    # APK was 4.2MB.  JRuby: 1.7.3, ANDROID_TARGET: 15
    # APK was 4.4MB.  JRuby: 1.7.4, ANDROID_TARGET: 10
    # APK was 8.2MB.  JRuby: 1.7.4, ANDROID_TARGET: 16
    # APK was 4.3MB.  JRuby: 1.7.5.dev, ANDROID_TARGET: 10
    # APK was 4.2MB.  JRuby: 1.7.5.dev, ANDROID_TARGET: 15
    # APK was 4.3MB.  JRuby: 1.7.5.dev, ANDROID_TARGET: 16
    # APK was 8.6MB.  JRuby: 1.7.8, ANDROID_TARGET: 16
    # APK was 6.4MB.  JRuby: 9000.dev, ANDROID_TARGET: 16
    def test_minimal_apk_is_within_limits
      apk_size = BigDecimal(File.size("#{APP_DIR}/bin/RubotoTestApp-debug.apk").to_s) / (1024 * 1024)
      upper_limit = {
          '1.7.0' => ANDROID_TARGET < 15 ? 4.7 : 4.9,
          '1.7.1' => ANDROID_TARGET < 15 ? 4.7 : 4.9,
          '1.7.2' => ANDROID_TARGET < 15 ? 4.6 : 4.9,
          '1.7.3' => ANDROID_TARGET < 15 ? 4.3 : 4.4,
          '1.7.4' => ANDROID_TARGET < 15 ? 4.4 : 8.2,
          '1.7.8' => ANDROID_TARGET < 15 ? 4.4 : 8.6,
          '9000.dev' => 6.4,
      }[JRUBY_JARS_VERSION.to_s] || 4.3
      lower_limit = upper_limit * 0.9
      version_message ="JRuby: #{JRUBY_JARS_VERSION}, ANDROID_TARGET: #{ANDROID_TARGET}"
      assert apk_size <= upper_limit, "APK was larger than #{'%.1f' % upper_limit}MB: #{'%.1f' % apk_size.ceil(1)}MB.  #{version_message}"
      assert apk_size >= lower_limit, "APK was smaller than #{'%.1f' % lower_limit}MB: #{'%.1f' % apk_size.floor(1)}MB.  You should lower the limit.  #{version_message}"
    end

    def test_minimal_apk_succeeds_tests
      run_app_tests
    end

  end
end
