require 'rexml/document'

PLATFORM_PROJECT = File.expand_path('tmp/RubotoCore', File.dirname(__FILE__))
PLATFORM_DEBUG_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-debug.apk"
PLATFORM_RELEASE_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-release.apk"
MANIFEST_FILE = "AndroidManifest.xml"

# FIXME(uwe):  Remove when we stop supporting JRuby 1.5.6
if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
  gem_spec = Gem::Specification.find_by_path 'jruby-jars'
else
  gem_spec = Gem.searcher.find('jruby-jars')
end
raise StandardError.new("Can't find Gem specification jruby-jars.") unless gem_spec
JRUBY_JARS_VERSION = gem_spec.version
ON_JRUBY_JARS_1_5_6 = JRUBY_JARS_VERSION == Gem::Version.new('1.5.6')
# FIXME end


task :default => :gem

desc "Generate a gem"
task :gem do
  `gem build ruboto-core.gemspec`
end

desc "Push the gem to RubyGems"
task :release do
  sh "gem push #{Dir['ruboto-core-*.gem'][-1]}"
end

desc "Run the tests"
task :test do
  FileUtils.rm_rf Dir['tmp/RubotoTestApp_template*']
  Dir['test/*_test.rb'].each do |f|
    require f.chomp('.rb')
  end
end

namespace :platform do
  desc 'Generate the Ruboto Core platform project'
  task :project => PLATFORM_PROJECT

  file PLATFORM_PROJECT do
    sh "ruby -rubygems -I#{File.expand_path('lib', File.dirname(__FILE__))} bin/ruboto gen app --package org.ruboto.core --name RubotoCore --with-jruby #{'--with-psych' unless ON_JRUBY_JARS_1_5_6} --path #{PLATFORM_PROJECT}"
    Dir.chdir(PLATFORM_PROJECT) do
      manifest = REXML::Document.new(File.read(MANIFEST_FILE))
      manifest.root.attributes['android:versionCode'] = '2'
      manifest.root.attributes['android:versionName'] = '0.4.1'
      manifest.root.attributes['android:installLocation'] = 'auto' # or 'preferExternal' ?
      manifest.root.elements['uses-sdk'].attributes['android:targetSdkVersion'] = '8'
      File.open(MANIFEST_FILE, 'w') { |f| manifest.document.write(f, 4) }
      File.open('default.properties', 'w'){|f| f << "target=android-8\n"}
      keystore_file = File.expand_path('~/android_market.keystore')
      if File.exists?(keystore_file)
        File.open('local.properties', 'a'){|f| f << "key.store=#{keystore_file}\nkey.alias=android_market\n"}
      end
    end
  end

  file PLATFORM_DEBUG_APK => PLATFORM_PROJECT do
    Dir.chdir(PLATFORM_PROJECT) do
      sh 'rake debug'
    end
  end

  desc 'Generate a Ruboto Core platform release apk'
  task :release => PLATFORM_RELEASE_APK

  file PLATFORM_RELEASE_APK => PLATFORM_PROJECT do
    Dir.chdir(PLATFORM_PROJECT) do
      sh 'rake release'
    end
  end

  desc 'Install the Ruboto Core platform debug apk'
  task :install => PLATFORM_DEBUG_APK do
    Dir.chdir(PLATFORM_PROJECT) do
      sh 'rake install'
    end
  end

  desc 'Uninstall the Ruboto Core platform debug apk'
  task :uninstall => PLATFORM_PROJECT do
    Dir.chdir(PLATFORM_PROJECT) do
      sh 'rake uninstall'
    end
  end
end
