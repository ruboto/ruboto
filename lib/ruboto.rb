require 'ruboto/util/objectspace'
# enable ObjectSpace in JRuby
Ruboto.enable_objectspace

require 'main'
require 'fileutils'
require 'rexml/document'

require 'ruboto/util/main_fix'

module Ruboto
  GEM_ROOT = File.dirname(File.dirname(__FILE__))
  ASSETS = File.join(GEM_ROOT, "assets")
  MINIMUM_SUPPORTED_SDK_LEVEL = 7
  MINIMUM_SUPPORTED_SDK = "android-#{MINIMUM_SUPPORTED_SDK_LEVEL}"
  DEFAULT_TARGET_SDK_LEVEL = 8
  DEFAULT_TARGET_SDK = "android-#{DEFAULT_TARGET_SDK_LEVEL}"
end
