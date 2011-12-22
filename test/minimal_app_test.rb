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
    limit = 3.0
    assert apk_size < limit, "APK was larger than #{'%.1f' % limit}MB: #{'%.1f' % apk_size.ceil(1)}MB"
  end

  def test_minimal_apk_succeeds_tests
    run_app_tests
  end

end
