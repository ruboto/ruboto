$:.unshift('lib') unless $:.include?('lib')
require 'rake/clean'
require 'rexml/document'
require 'ruboto/version'
require 'ruboto/sdk_versions'

PLATFORM_PROJECT = File.expand_path('tmp/RubotoCore', File.dirname(__FILE__))
PLATFORM_DEBUG_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-debug.apk"
PLATFORM_RELEASE_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-release.apk"
MANIFEST_FILE = "AndroidManifest.xml"
GEM_FILE = "ruboto-#{Ruboto::VERSION}.gem"
GEM_FILE_OLD = "ruboto-core-#{Ruboto::VERSION}.gem"
GEM_SPEC_FILE = 'ruboto.gemspec'
GEM_SPEC_FILE_OLD = 'ruboto-core.gemspec'
EXAMPLE_FILE = File.expand_path("examples/RubotoTestApp_#{Ruboto::VERSION}_tools_r#{Ruboto::SdkVersions::ANDROID_TOOLS_REVISION}.tgz", File.dirname(__FILE__))

CLEAN.include('ruboto-*.gem', 'tmp')

task :default => :gem

desc "Generate a gem"
task :gem => [GEM_FILE, GEM_FILE_OLD]

file GEM_FILE => GEM_SPEC_FILE do
  puts "Generating #{GEM_FILE}"
  `gem build #{GEM_SPEC_FILE}`
end

file GEM_FILE_OLD => GEM_SPEC_FILE_OLD do
  puts "Generating #{GEM_FILE_OLD}"
  `gem build #{GEM_SPEC_FILE_OLD}`
end

task :install => :gem do
  `gem query -i -n ^ruboto$ -v #{Ruboto::VERSION}`
  if $? != 0
    cmd = "gem install ruboto-#{Ruboto::VERSION}.gem"
    output = `#{cmd}`
    if $? == 0
      puts output
    else
      sh "sudo #{cmd}"
    end
  end
end

desc "Generate an example app"
task :example => EXAMPLE_FILE

file EXAMPLE_FILE => :install do
  puts "Creating example app #{EXAMPLE_FILE}"
  app_name = 'RubotoTestApp'
  Dir.chdir File.dirname(EXAMPLE_FILE) do
    FileUtils.rm_rf app_name
    sh "ruboto gen app --package org.ruboto.test_app --name #{app_name} --path #{app_name}"
    sh "tar czf #{EXAMPLE_FILE} #{app_name}"
    FileUtils.rm_rf app_name
  end
end

desc "Push the gem to RubyGems"
task :release => [:clean, :gem] do
  output = `git status --porcelain`
  raise "Workspace not clean!\n#{output}" unless output.empty?
  sh "git tag #{Ruboto::VERSION}"
  sh "git push --tags"
  sh "gem push #{GEM_FILE}"
  sh "gem push #{GEM_FILE_OLD}"

  Rake::Task[:example].invoke
  sh "git add #{EXAMPLE_FILE}"
  sh "git commit -m '* Added example app for Ruboto #{Ruboto::VERSION} tools r#{Ruboto::SdkVersions::ANDROID_TOOLS_REVISION}' #{EXAMPLE_FILE}"
  sh "git push"
end

desc "Run the tests"
task :test do
  FileUtils.rm_rf Dir['tmp/RubotoTestApp_template*']
  Dir['test/*_test.rb'].each do |f|
    require f.chomp('.rb')
  end
end

namespace :platform do
  desc 'Remove Ruboto Core platform project'
  task :clean do
    FileUtils.rm_rf PLATFORM_PROJECT
  end

  desc 'Generate the Ruboto Core platform project'
  task :project => PLATFORM_PROJECT

  file PLATFORM_PROJECT do
    sh "ruby -rubygems -I#{File.expand_path('lib', File.dirname(__FILE__))} bin/ruboto gen app --package org.ruboto.core --name RubotoCore --with-jruby --path #{PLATFORM_PROJECT} --min-sdk #{Ruboto::SdkVersions::MINIMUM_SUPPORTED_SDK} --target #{Ruboto::SdkVersions::DEFAULT_TARGET_SDK}"
    Dir.chdir(PLATFORM_PROJECT) do
      manifest = REXML::Document.new(File.read(MANIFEST_FILE))
      manifest.root.attributes['android:versionCode'] = '408'
      manifest.root.attributes['android:versionName'] = '0.4.8'
      manifest.root.attributes['android:installLocation'] = 'auto' # or 'preferExternal' ?
      File.open(MANIFEST_FILE, 'w') { |f| manifest.document.write(f, 4) }
      File.open('Gemfile.apk', 'w'){|f| f << "source :rubygems\n\ngem 'activerecord-jdbc-adapter'\n"}

      # FIXME(uwe):  Add this when either jruby-openssl is simplified or most devices are Android 4
      # FIXME(uwe):  Reeference: #154 and http://code.google.com/p/android/issues/detail?id=22586
      # File.open('Gemfile.apk', 'w'){|f| f << "gem 'jruby-openssl'\n"}
      # FIXME end

      File.open('ant.properties', 'a'){|f| f << "key.store=${user.home}/ruboto_core.keystore\nkey.alias=Ruboto\n"}
    end
  end

  desc 'Generate a Ruboto Core platform debug apk'
  task :debug => PLATFORM_DEBUG_APK

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
