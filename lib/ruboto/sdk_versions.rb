require 'pathname'

module Ruboto
  module SdkVersions
    MINIMUM_SUPPORTED_SDK_LEVEL = 7
    MINIMUM_SUPPORTED_SDK = "android-#{MINIMUM_SUPPORTED_SDK_LEVEL}"
    DEFAULT_TARGET_SDK_LEVEL = 8
    DEFAULT_TARGET_SDK = "android-#{DEFAULT_TARGET_SDK_LEVEL}"
    if ENV['ANDROID_HOME']
      ANDROID_HOME = ENV['ANDROID_HOME']
    else
      adb_location = `#{RUBY_PLATFORM =~ /mingw|mswin/ ? 'where' : 'which'} adb`.chomp
      if adb_location.empty?
        raise 'Unable to locate the "adb" command.  Either set the ANDROID_HOME environment variable or add the location of the "adb" command to your path.'
      end
      ANDROID_HOME = File.dirname(File.dirname(Pathname.new(adb_location).realpath))
      unless File.exists? "#{ANDROID_HOME}/tools"
        raise "Found '#{adb_location}' but it is not in a proper Android SDK installation.
The 'tools' directory is missing.
Please set the ANDROID_HOME environment variable."
      end
    end
    ANDROID_TOOLS_REVISION = File.read("#{ANDROID_HOME}/tools/source.properties").slice(/Pkg.Revision=\d+/).slice(/\d+$/).to_i
  end
end
