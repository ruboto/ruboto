require File.expand_path('test_helper', File.dirname(__FILE__))
require 'net/http'

class RubotoSetupTest < Test::Unit::TestCase
  SDK_DOWNLOAD_PAGE = 'http://developer.android.com/sdk/index.html?hl=sk'

  def test_if_page_still_exists
    uri = URI.parse(SDK_DOWNLOAD_PAGE)
    res = Net::HTTP.get_response(uri)

    assert_equal 200, res.code.to_i
  end

  def test_if_regex_still_applies_to_sdk
    regex = '(\>installer_.*.exe)'
    page_content = Net::HTTP.get(URI.parse(SDK_DOWNLOAD_PAGE))
    link = page_content.scan(/#{regex}/).to_s

    assert_match /\d+(\.\d+)?(\.\d+)?/, link 
  end

end
