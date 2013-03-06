require 'pathname'

module Ruboto
  module SdkVersions
    VERSION_TO_API_LEVEL = {
        '2.1' => 'android-7', '2.1-update1' => 'android-7', '2.2' => 'android-8',
        '2.3' => 'android-9', '2.3.1' => 'android-9', '2.3.2' => 'android-9',
        '2.3.3' => 'android-10', '2.3.4' => 'android-10',
        '3.0' => 'android-11', '3.1' => 'android-12', '3.2' => 'android-13',
        '4.0.1' => 'android-14', '4.0.3' => 'android-15', '4.0.4' => 'android-15',
        '4.1' => 'android-16', '4.1.1' => 'android-16', '4.1.2' => 'android-16',
        '4.2' => 'android-17', '4.2.2' => 'android-17',
    }
    API_LEVEL_TO_VERSION = {
        7 => '2.1', 8 => '2.2', 10 => '2.3.3', 11 => '3.0', 12 => '3.1',
        13 => '3.2', 14 => '4.0', 15 => '4.0.3', 16 => '4.1.2', 17 => '4.2.2',
    }
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
        puts "Found '#{adb_location}' but it is not in a proper Android SDK installation."
      end
    end
    unless File.exists? "#{ANDROID_HOME}/tools"
      raise "The '<ANDROID_HOME>/tools' directory is missing.
Please set the ANDROID_HOME environment variable to a proper Android SDK installation."
    end
    ANDROID_TOOLS_REVISION = File.read("#{ANDROID_HOME}/tools/source.properties").slice(/Pkg.Revision=\d+/).slice(/\d+$/).to_i
  end
end
