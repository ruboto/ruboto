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
    # APK was 4.3MB.  JRuby: 1.7.5.dev, ANDROID_TARGET: 10
    # APK was 4.2MB.  JRuby: 1.7.5.dev, ANDROID_TARGET: 15
    # APK was 5.1MB.  JRuby: 1.7.5.dev, ANDROID_TARGET: 16
    def test_minimal_apk_is_within_limits
      apk_size = BigDecimal(File.size("#{APP_DIR}/bin/RubotoTestApp-debug.apk").to_s) / (1024 * 1024)
      upper_limit = {
          '1.7.0' => ANDROID_TARGET < 15 ? 4.7 : 4.9,
          '1.7.1' => ANDROID_TARGET < 15 ? 4.7 : 4.9,
          '1.7.2' => ANDROID_TARGET < 15 ? 4.6 : 4.9,
          '1.7.3' => ANDROID_TARGET < 15 ? 4.3 : 4.4,
          '1.7.4' => 4.4,
      }[JRUBY_JARS_VERSION.to_s] || {10 => 4.3, 16 => 5.1}[ANDROID_TARGET] || 4.3
      lower_limit = upper_limit * 0.9
      version_message ="JRuby: #{JRUBY_JARS_VERSION}, ANDROID_TARGET: #{ANDROID_TARGET}"
      assert apk_size <= upper_limit, "APK was larger than #{'%.1f' % upper_limit}MB: #{'%.1f' % apk_size.ceil(1)}MB.  #{version_message}"
      assert apk_size >= lower_limit, "APK was smaller than #{'%.1f' % lower_limit}MB: #{'%.1f' % apk_size.floor(1)}MB.  You should lower the limit.  #{version_message}"
    end

    def test_minimal_apk_succeeds_tests
      run_app_tests
    end

    # APK was 4.7MB.  JRuby: 1.7.0, ANDROID_TARGET: 15
    # APK was 4.5MB.  JRuby: 1.7.2, ANDROID_TARGET: 10
    # APK was 4.5MB.  JRuby: 1.7.2, ANDROID_TARGET: 15
    # APK was 4.5MB.  JRuby: 1.7.3, ANDROID_TARGET: 10
    # APK was 4.6MB.  JRuby: 1.7.3.dev, ANDROID_TARGET: 10
    # APK was 4.5MB.  JRuby: 1.7.3.dev, ANDROID_TARGET: 15
    # APK was 4.9MB.  JRuby: 1.7.4, ANDROID_TARGET: 10
    # APK was 5.1MB.  JRuby: 1.7.5.dev, ANDROID_TARGET: 15
    # FIXME(uwe): Remove when we remove the exclude feature
    def test_minimal_apk_with_excludes_is_less_than_5_mb
      generate_app :excluded_stdlibs => %w{ant cgi digest dl drb ffi irb net optparse racc rbconfig rdoc rexml rinda rss
        rubygems runit shell soap test uri webrick win32 wsdl xmlrpc xsd ../1.9}
      apk_size = BigDecimal(File.size("#{APP_DIR}/bin/RubotoTestApp-debug.apk").to_s) / (1024 * 1024)
      upper_limit = {
          '1.7.0' => ANDROID_TARGET < 15 ? 4.7 : 4.9,
          '1.7.1' => ANDROID_TARGET < 15 ? 4.7 : 4.9,
          '1.7.2' => ANDROID_TARGET < 15 ? 4.6 : 4.9,
          '1.7.3' => ANDROID_TARGET < 15 ? 4.6 : 4.9,
          '1.7.4' => ANDROID_TARGET < 15 ? 4.9 : 5.1,
      }[JRUBY_JARS_VERSION.to_s] || {10 => 5.1, 15 => 5.1, 16 => 5.1}[ANDROID_TARGET]
      lower_limit = upper_limit * 0.9
      version_message ="JRuby: #{JRUBY_JARS_VERSION}, ANDROID_TARGET: #{ANDROID_TARGET}"
      assert apk_size <= upper_limit, "APK was larger than #{'%.1f' % upper_limit}MB: #{'%.1f' % apk_size.ceil(1)}MB.  #{version_message}"
      assert apk_size >= lower_limit, "APK was smaller than #{'%.1f' % lower_limit}MB: #{'%.1f' % apk_size.floor(1)}MB.  You should lower the limit.  #{version_message}"
    end

  end
end
