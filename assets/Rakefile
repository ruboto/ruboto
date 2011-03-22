# callback_reflection.rb creates the interfaces.txt (JRuby can't do YAML with ruby 1.8, so it's just
# and inspect on the hash) on a device. Bring it off the device and put it in the callback_gen dir.
#
# Move this into a rake task later.
#


if RUBY_PLATFORM =~ /java/
  puts "Detected JRuby.  Loading ANT."
  require 'ant'
  ant_loaded = true
end

require 'rake/clean'
require 'rexml/document'

generated_libs     = 'generated_libs'
jars = Dir['libs/*.jar']
stdlib             = jars.grep(/stdlib/).first #libs/jruby-stdlib-VERSION.jar
jruby_jar          = jars.grep(/core/).first   #libs/jruby-core-VERSION.jar
stdlib_precompiled = File.join(generated_libs, 'jruby-stdlib-precompiled.jar')
jruby_ruboto_jar   = File.join(generated_libs, 'jruby-ruboto.jar')
ant.property :name=>'external.libs.dir', :value => generated_libs if ant_loaded
dirs = ['tmp/ruby', 'tmp/precompiled', generated_libs]
dirs.each { |d| directory d }

CLEAN.include('tmp', 'bin', generated_libs)

ant_import if ant_loaded

file stdlib_precompiled => :compile_stdlib
file jruby_ruboto_jar => generated_libs do
  ant.zip(:destfile=>jruby_ruboto_jar) do
    zipfileset(:src=>jruby_jar) do
      exclude(:name=>'jni/**')
      # dx chokes on some of the netdb classes, for some reason
      exclude(:name=>'jnr/netdb/**')
    end
  end
end

desc "precompile ruby stdlib"
task :compile_stdlib => [:clean, *dirs] do
  ant.unzip(:src=>stdlib, :dest=>'tmp/ruby')
  Dir.chdir('tmp/ruby') { sh "jrubyc . -t ../precompiled" }
  ant.zip(:destfile=>stdlib_precompiled, :basedir=>'tmp/precompiled')
end

task :generate_libs => [generated_libs, jruby_ruboto_jar] do
  cp stdlib, generated_libs
end

task :debug   => :generate_libs
task :release => :generate_libs

task :default => :debug

task :tag => :release do
  unless `git branch` =~ /^\* master$/
    puts "You must be on the master branch to release!"
    exit!
  end
  sh "git commit --allow-empty -a -m 'Release #{version}'"
  sh "git tag #{version}"
  sh "git push origin master --tags"
  #sh "gem push pkg/#{name}-#{version}.gem"
end

task :sign => :release do
  sh "jarsigner -keystore #{ENV['RUBOTO_KEYSTORE']} -signedjar bin/#{build_project_name}.apk bin/#{build_project_name}-unsigned.apk #{ENV['RUBOTO_KEY_ALIAS']}"
end

task :align => :sign do
  sh "zipalign 4 bin/#{build_project_name}.apk #{build_project_name}.apk"
end

task :publish => :align do
  puts "#{build_project_name}.apk is ready for the market!"
end

task :start_app do
  `adb shell am start -a android.intent.action.MAIN -n #{package}/.#{main_activity}`
end

task :stop_app do
  `adb shell ps | grep #{package} | awk '{print $2}' | xargs adb shell kill`
end

task :restart => [:stop_app, :start_app]

task :uninstall do
  system "adb uninstall #{package}"
end

namespace :install do
  desc 'Build, install, and restart the application'
  task :restart => [:install, :start_app]
  namespace :restart do
    desc 'Uninstall, build, install, and restart the application'
    task :clean => [:uninstall, :install, :start_app]
  end
end

desc 'Copy scripts to emulator'
task :update_scripts do
  manifest
  Dir.chdir('assets') do
    # Add more directories here if you want them copied to the emulator
    ['scripts'].each do |script_dir|
      Dir["#{script_dir}/*"].each do |script|
        next if File.directory? script
        `adb push #{script} /data/data/#{package}/files/#{script_dir}`
      end
    end
  end
end

namespace :update_scripts do
  desc 'Copy scripts to emulator and restart the app'
  task :restart => [:stop_app, :update_scripts, :start_app]
end

task :update_test_scripts do
  Dir['test/assets/scripts/*.rb'].each do |script|
    `adb push #{script} /data/data/#{package}.tests/files/scripts/`
  end
  `adb shell ps | grep #{package}.tests | awk '{print $2}' | xargs adb shell kill`
end

task :test => :uninstall do
  Dir.chdir('test') do
    puts 'Running tests'
    system "adb uninstall #{package}.tests"
    system "ant run-tests"
  end
end

namespace :test do
  task :quick => [:update_scripts, :update_test_scripts] do
    Dir.chdir('test') do
      puts 'Running quick tests'
      system "ant run-tests-quick"
    end
  end
end

def manifest
  @manifest ||= REXML::Document.new(File.read('AndroidManifest.xml'))
end

def strings(name)
  @strings ||= REXML::Document.new(File.read('res/values/strings.xml'))
  value = @strings.elements["//string[@name='#{name.to_s}']"] or raise "string '#{name}' not found in strings.xml"
  value.text
end

def package() manifest.root.attribute('package') end
def version() strings :version_name end
def app_name() strings :app_name end
def main_activity() manifest.root.elements['application'].elements['activity'].attributes['android:name'] end
def build_project_name() @build_project_name ||= REXML::Document.new(File.read('build.xml')).elements['project'].attribute(:name).value end
