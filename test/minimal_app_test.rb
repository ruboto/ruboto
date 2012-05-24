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

    def test_minimal_apk_is_less_than_3_mb
      apk_size = BigDecimal(File.size("#{APP_DIR}/bin/RubotoTestApp-debug.apk").to_s) / (1024 * 1024)
      upper_limit = {
          # '1.5.6' => 3.7,
          '1.6.7' => 3.2,
          '1.7.0.preview1' => ANDROID_TARGET < 15 ? 4.3 : 4.6, # Without dexmaker for Android < 4.0.3
      }[JRUBY_JARS_VERSION.to_s] || 3.2
      lower_limit = upper_limit * 0.9
      version_message ="JRuby: #{JRUBY_JARS_VERSION}"
      assert apk_size <= upper_limit, "APK was larger than #{'%.1f' % upper_limit}MB: #{'%.1f' % apk_size.ceil(1)}MB.  #{version_message}"
      assert apk_size >= lower_limit, "APK was smaller than #{'%.1f' % lower_limit}MB: #{'%.1f' % apk_size.floor(1)}MB.  You should lower the limit.  #{version_message}"
    end

    def test_minimal_apk_succeeds_tests
      run_app_tests
    end

  end
end