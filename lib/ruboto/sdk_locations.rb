require 'pathname'
require 'ruboto/util/setup'

module Ruboto
  module SdkLocations
    extend Ruboto::Util::Setup
    ANDROID_HOME = android_package_directory
    unless File.exist?("#{ANDROID_HOME}/platform-tools/adb")
      abort 'Unable to locate the "adb" command.  Either set the ANDROID_HOME environment variable or add the location of the "adb" command to your path.'
    end
    if File.exist? "#{ANDROID_HOME}/tools/source.properties"
      ANDROID_TOOLS_REVISION = File.read("#{ANDROID_HOME}/tools/source.properties").slice(/Pkg.Revision=\d+/).slice(/\d+$/).to_i
    elsif File.exist? "#{ANDROID_HOME}/cmdline-tools/latest/source.properties"
      ANDROID_TOOLS_REVISION = File.read("#{ANDROID_HOME}/cmdline-tools/latest/source.properties").slice(/Pkg.Revision=[\d.]+/).slice(/[\d.]+$/).split('.').first.to_i
    else
      abort "Cannot find Android SDK tools. Please set the ANDROID_HOME environment variable to a proper Android SDK installation."
    end
    ENV['ANDROID_HOME'] = ANDROID_HOME
    ENV['ANDROID_SDK_ROOT'] = ANDROID_HOME
  end
end
