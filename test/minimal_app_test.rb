require File.expand_path("test_helper", File.dirname(__FILE__))

if RubotoTest::RUBOTO_PLATFORM == 'STANDALONE'
  require 'bigdecimal'

  class MinimalAppTest < Test::Unit::TestCase
    def setup
      generate_app :excluded_stdlibs => %w{ant cgi digest dl drb ffi irb net optparse racc rbconfig rdoc rexml rinda rss
        rubygems runit shell soap test uri webrick win32 wsdl xmlrpc xsd ../1.9}
    end

    def teardown
      cleanup_app
    end

    # APK was larger than 3.2MB: 3.5MB.  JRuby: 1.6.7,          ANDROID_TARGET: 15.
    # APK was larger than 3.2MB: 3.3MB.  JRuby: 1.6.7.2,        ANDROID_TARGET: 10.
    # APK was larger than 4.4MB: 4.7MB.  JRuby: 1.7.0.preview2, ANDROID_TARGET: 10.
    # APK was larger than 4.6MB: 4.9MB.  JRuby: 1.7.0.preview2, ANDROID_TARGET: 15.
    # APK was larger than 3.2MB: 4.7MB.  JRuby: 1.7.0,          ANDROID_TARGET: 15.
    # APK was larger than 4.9MB: 7.2MB.  JRuby: 1.7.2.dev,      ANDROID_TARGET: 10.

    def test_minimal_apk_is_less_than_3_mb
      apk_size = BigDecimal(File.size("#{APP_DIR}/bin/RubotoTestApp-debug.apk").to_s) / (1024 * 1024)
      upper_limit = {
          '1.6.7' => 3.5,
          '1.6.7.2' => 3.5,
          '1.6.8' => 3.5,
          '1.7.0' => ANDROID_TARGET < 15 ? 4.7 : 4.9,
          '1.7.1.dev' => ANDROID_TARGET < 15 ? 4.7 : 4.9,
          '1.7.2.dev' => 7.2,
      }[JRUBY_JARS_VERSION.to_s] || 4.9
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
