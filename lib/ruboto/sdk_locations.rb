require 'pathname'

module Ruboto
  module SdkLocations
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
