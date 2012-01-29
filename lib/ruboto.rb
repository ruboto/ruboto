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
  MINIMUM_SUPPORTED_SDK = 'android-7'
end