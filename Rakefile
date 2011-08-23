PLATFORM_PROJECT = File.expand_path('tmp/RubotoCore', File.dirname(__FILE__))
PLATFORM_DEBUG_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-debug.apk"
PLATFORM_RELEASE_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-release.apk"

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

desc 'Generate the Ruboto Core platform project'
file PLATFORM_PROJECT do
  sh "ruby -rubygems -I#{File.expand_path('lib', File.dirname(__FILE__))} bin/ruboto gen app --package org.ruboto.core --name RubotoCore --with-jruby --with-psych --path #{PLATFORM_PROJECT}"
end

desc 'Generate a Ruboto Core platform debug apk'
file PLATFORM_DEBUG_APK => PLATFORM_PROJECT do
  Dir.chdir(PLATFORM_PROJECT) do
    sh 'rake debug'
  end
end

desc 'Generate a Ruboto Core platform release apk'
file PLATFORM_RELEASE_APK do
  Dir.chdir(PLATFORM_PROJECT) do
    sh 'rake release'
  end
end

desc 'Install the Ruboto Core platform debug apk'
task :install_platform => PLATFORM_DEBUG_APK do
  Dir.chdir(PLATFORM_PROJECT) do
    sh 'rake install'
  end
end
