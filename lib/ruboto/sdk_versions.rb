require 'pathname'

module Ruboto
  module SdkVersions
    MINIMUM_SUPPORTED_SDK_LEVEL = 7
    MINIMUM_SUPPORTED_SDK = "android-#{MINIMUM_SUPPORTED_SDK_LEVEL}"
    DEFAULT_TARGET_SDK_LEVEL = 8
    DEFAULT_TARGET_SDK = "android-#{DEFAULT_TARGET_SDK_LEVEL}"
    ANDROID_HOME = ENV['ANDROID_HOME'] || File.dirname(File.dirname(Pathname.new(`#{RUBY_PLATFORM =~ /mingw|mswin/ ? "where" : "which"} adb`.chomp).realpath))
    ANDROID_TOOLS_REVISION = File.read("#{ANDROID_HOME}/tools/source.properties").slice(/Pkg.Revision=\d+/).slice(/\d+$/).to_i
  end
end
