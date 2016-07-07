require File.expand_path('test_helper', File.dirname(__FILE__))
require 'net/http'

class RubotoSetupTest < Minitest::Test
  include Ruboto::Util::Setup

  SDK_DOWNLOAD_PAGE = 'https://developer.android.com/studio/index.html'
  REPOSITORY_BASE = 'http://dl-ssl.google.com/android/repository'
  ADDONS_URL = "#{REPOSITORY_BASE}/extras/intel/addon.xml"
  HAXM_URL = 'https://software.intel.com/sites/default/files/managed/dd/21'

  def test_if_sdk_page_still_exists?
    uri = URI.parse(SDK_DOWNLOAD_PAGE)
    res = Net::HTTP.get_response(uri)
    assert_equal 200, res.code.to_i
  end

  def test_if_haxm_version_page_still_exists?
    uri = URI.parse(ADDONS_URL)
    res = Net::HTTP.get_response(uri)
    assert_equal 200, res.code.to_i
  end

  def test_if_haxm_download_still_exists?
    filename, version = get_new_haxm_filename
    unless (filename.empty? || version.empty?)
      uri = URI.parse("#{HAXM_URL}/#{filename}")
      res = Net::HTTP.get_response(uri)
      assert_equal 200, res.code.to_i
    end
  end

  def test_if_regex_still_applies_to_sdk
    regex = '(\>installer_.*.exe)'
    page_content = Net::HTTP.get(URI.parse(SDK_DOWNLOAD_PAGE))
    link = page_content.scan(/#{regex}/).to_s
    assert_match /\d+(\.\d+)?(\.\d+)?/, link
  end

  describe 'Upgrade HAXM' do
    include Ruboto::Util::Setup
    it 'should get the new HAXM file name and version' do
      filename, version = get_new_haxm_filename
      unless (filename.empty? || version.empty?)
        filename.must_match /haxm-(.*)\.zip/
        version.must_match /\d\.\d\.\d/
      end
    end
  end

end
