require_relative 'test_helper'
require 'net/http'

class RubotoSetupTest < Minitest::Test
  include Ruboto::Util::Setup

  # TODO: (uwe) The following tests verify internals of Ruboto setup.  Should test API instead.
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
      uri = URI.parse("#{File.dirname(ADDONS_URL)}/#{filename}")
      res = Net::HTTP.get_response(uri)
      assert_equal 200, res.code.to_i, uri
    end
  end

  def test_if_regex_still_applies_to_sdk
    regex = '(\>tools_r.*.zip)'
    page_content = Net::HTTP.get(URI.parse(SDK_DOWNLOAD_PAGE))
    link = page_content.scan(/#{regex}/).to_s
    assert_match /\d+(\.\d+)?(\.\d+)?/, link, page_content
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
