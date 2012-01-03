require File.expand_path("test_helper", File.dirname(__FILE__))
require 'bigdecimal'

class MinimalAppTest < Test::Unit::TestCase
  def setup
    generate_app :excluded_stdlibs => %w{ant cgi digest dl drb ffi irb net optparse racc rbconfig rdoc rexml rinda rss rubygems runit shell soap test uri webrick win32 wsdl xmlrpc xsd}
  end

  def teardown
    cleanup_app
  end

  def test_minimal_apk_is_less_than_3_mb
    apk_size = BigDecimal(File.size("#{APP_DIR}/bin/RubotoTestApp-debug.apk").to_s) / (1024 * 1024)
    upper_limit = 3.1
    lower_limit = upper_limit * 0.85
    assert apk_size <= upper_limit, "APK was larger than #{'%.1f' % upper_limit}MB: #{'%.1f' % apk_size.ceil(1)}MB"
    assert apk_size >= lower_limit, "APK was smaller than #{'%.1f' % lower_limit}MB: #{'%.1f' % apk_size.floor(1)}MB.  You should lower the limit."
  end

  def test_minimal_apk_succeeds_tests
    run_app_tests
  end

end
