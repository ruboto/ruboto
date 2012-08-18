if `ant -version` !~ /version (\d+)\.(\d+)\.(\d+)/ || $1.to_i < 1 || ($1.to_i == 1 && $2.to_i < 8)
  puts "ANT version 1.8.0 or later required.  Version found: #{$1}.#{$2}.#{$3}"
  exit 1
end

require 'time'

def manifest() @manifest ||= REXML::Document.new(File.read(MANIFEST_FILE)) end
def package() manifest.root.attribute('package') end
def build_project_name() @build_project_name ||= REXML::Document.new(File.read('build.xml')).elements['project'].attribute(:name).value end
def scripts_path() @sdcard_path ||= "/mnt/sdcard/Android/data/#{package}/files/scripts" end
def app_files_path() @app_files_path ||= "/data/data/#{package}/files" end

require 'rake/clean'
require 'rexml/document'

PROJECT_DIR        = File.expand_path('..', File.dirname(__FILE__))
UPDATE_MARKER_FILE = File.join(PROJECT_DIR, 'bin', 'LAST_UPDATE')
BUNDLE_JAR         = File.expand_path 'libs/bundle.jar'
BUNDLE_PATH        = File.expand_path 'bin/bundle'
MANIFEST_FILE      = File.expand_path 'AndroidManifest.xml'
PROJECT_PROPS_FILE = File.expand_path 'project.properties'
RUBOTO_CONFIG_FILE = File.expand_path 'ruboto.yml'
GEM_FILE           = File.expand_path('Gemfile.apk')
GEM_LOCK_FILE      = File.expand_path('Gemfile.apk.lock')
RELEASE_APK_FILE   = File.expand_path "bin/#{build_project_name}-release.apk"
APK_FILE           = File.expand_path "bin/#{build_project_name}-debug.apk"
TEST_APK_FILE      = File.expand_path "test/bin/#{build_project_name}Test-debug.apk"
JRUBY_JARS         = Dir[File.expand_path 'libs/jruby-*.jar']
RESOURCE_FILES     = Dir[File.expand_path 'res/**/*']
JAVA_SOURCE_FILES  = Dir[File.expand_path 'src/**/*.java']
RUBY_SOURCE_FILES  = Dir[File.expand_path 'src/**/*.rb']
APK_DEPENDENCIES   = [MANIFEST_FILE, RUBOTO_CONFIG_FILE, BUNDLE_JAR] + JRUBY_JARS + JAVA_SOURCE_FILES + RESOURCE_FILES + RUBY_SOURCE_FILES
KEYSTORE_FILE      = (key_store = File.readlines('ant.properties').grep(/^key.store=/).first) ? File.expand_path(key_store.chomp.sub(/^key.store=/, '').sub('${user.home}', '~')) : "#{build_project_name}.keystore"
KEYSTORE_ALIAS     = (key_alias = File.readlines('ant.properties').grep(/^key.alias=/).first) ? key_alias.chomp.sub(/^key.alias=/, '') : build_project_name

CLEAN.include('bin')

task :default => :debug

file JRUBY_JARS => RUBOTO_CONFIG_FILE do
  next unless File.exists? RUBOTO_CONFIG_FILE
  jruby_jars_mtime = JRUBY_JARS.map { |f| File.mtime(f) }.min
  ruboto_yml_mtime = File.mtime(RUBOTO_CONFIG_FILE)
  next if jruby_jars_mtime > ruboto_yml_mtime
  puts '*' * 80
  if JRUBY_JARS.empty?
    puts '  The JRuby jars are missing.'
  else
    puts "  The JRuby jars need reconfiguring after changes to #{RUBOTO_CONFIG_FILE}"
    puts "  #{RUBOTO_CONFIG_FILE}: #{ruboto_yml_mtime}"
    puts "  #{JRUBY_JARS.join(', ')}: #{jruby_jars_mtime}"
  end
  puts '  Run "ruboto update jruby" to regenerate the JRuby jars'
  puts '*' * 80
end

desc 'build debug package'
task :debug => APK_FILE

namespace :debug do
  desc 'build debug package if compiled files have changed'
  task :quick => [MANIFEST_FILE, RUBOTO_CONFIG_FILE, BUNDLE_JAR] + JRUBY_JARS + JAVA_SOURCE_FILES + RESOURCE_FILES do |t|
    build_apk(t, false)
  end
end

desc "build package and install it on the emulator or device"
task :install => APK_FILE do
  install_apk
end

namespace :install do
  desc 'uninstall, build, and install the application'
  task :clean => [:uninstall, APK_FILE, :install]

  desc 'Install the application, but only if compiled files are changed.'
  task :quick => 'debug:quick' do
    install_apk
  end
end

desc 'Build APK for release'
task :release => RELEASE_APK_FILE

file RELEASE_APK_FILE => [KEYSTORE_FILE] + APK_DEPENDENCIES do |t|
  build_apk(t, true)
end

desc 'Create a keystore for signing the release APK'
file KEYSTORE_FILE do
  unless File.read('ant.properties') =~ /^key.store=/
    File.open('ant.properties', 'a'){|f| f << "\nkey.store=#{KEYSTORE_FILE}\n"}
  end
  unless File.read('ant.properties') =~ /^key.alias=/
    File.open('ant.properties', 'a'){|f| f << "\nkey.alias=#{KEYSTORE_ALIAS}\n"}
  end
  sh "keytool -genkey -v -keystore #{KEYSTORE_FILE} -alias #{KEYSTORE_ALIAS} -keyalg RSA -keysize 2048 -validity 10000"
end

desc 'Tag this working copy with the current version'
task :tag => :release do
  unless `git branch` =~ /^\* master$/
    puts "You must be on the master branch to release!"
    exit!
  end
  # sh "git commit --allow-empty -a -m 'Release #{version}'"
  output = `git status --porcelain`
  raise "Workspace not clean!\n#{output}" unless output.empty?
  sh "git tag #{version}"
  sh "git push origin master --tags"
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

desc 'Start the emulator with larger disk'
task :emulator do
  sh 'emulator -partition-size 1024 -avd Android_3.0'
end

desc 'Start the application on the device/emulator.'
task :start do
  start_app
end

desc 'Stop the application on the device/emulator (requires emulator or rooted device).'
task :stop do
  raise "Unable to stop app.  Only available on emulator." unless stop_app
end

desc 'Restart the application'
task :restart => [:stop, :start]

task :uninstall do
  uninstall_apk
end

file PROJECT_PROPS_FILE
file MANIFEST_FILE => PROJECT_PROPS_FILE do
  sdk_level = File.read(PROJECT_PROPS_FILE).scan(/(?:target=android-)(\d+)/)[0][0].to_i
  old_manifest = File.read(MANIFEST_FILE)
  manifest = old_manifest.dup
  manifest.sub!(/(android:minSdkVersion=').*?(')/){|m| "#$1#{sdk_level}#$2"}
  manifest.sub!(/(android:targetSdkVersion=').*?(')/){|m| "#$1#{sdk_level}#$2"}
  File.open(MANIFEST_FILE, 'w'){|f| f << manifest} if manifest != old_manifest
end

file RUBOTO_CONFIG_FILE

file APK_FILE => APK_DEPENDENCIES do |t|
  build_apk(t, false)
end

desc 'Copy scripts to emulator or device'
task :update_scripts => ['install:quick'] do
  update_scripts
end

namespace :update_scripts do
  desc 'Copy scripts to emulator and restart the app'
  task :restart => APK_DEPENDENCIES do |t|
    if build_apk(t, false) || !stop_app
      install_apk
    else
      update_scripts
    end
    start_app
  end
end

task :test => :uninstall do
  Dir.chdir('test') do
    puts 'Running tests'
    sh "adb uninstall #{package}.tests"
    sh "ant instrument install test"
  end
end

namespace :test do
  task :quick => :update_scripts do
    Dir.chdir('test') do
      puts 'Running quick tests'
      sh 'ant instrument'
      sh 'ant installi'
      sh "ant run-tests-quick"
    end
  end
end

file GEM_FILE
file GEM_LOCK_FILE

desc 'Generate bundle jar from Gemfile'
task :bundle => BUNDLE_JAR

file BUNDLE_JAR => [GEM_FILE, GEM_LOCK_FILE] do
  next unless File.exists? GEM_FILE
  puts "Generating #{BUNDLE_JAR}"

  FileUtils.mkdir_p BUNDLE_PATH
  sh "bundle install --gemfile #{GEM_FILE} --path=#{BUNDLE_PATH}"

  gem_paths = Dir["#{BUNDLE_PATH}/{{,j}ruby,rbx}/{1.8,1.9{,.1},shared}/gems"]
  raise "Gem path not found" if gem_paths.empty?
  raise "Found multiple gem paths: #{gem_paths}" if gem_paths.size > 1
  gem_path = gem_paths[0]
  puts "Found gems in #{gem_path}"

  if package != 'org.ruboto.core' && JRUBY_JARS.none? { |f| File.exists? f }
    Dir.chdir gem_path do
      Dir['{activerecord-jdbc-adapter, jruby-openssl}-*'].each do |g|
        puts "Removing #{g} gem since it is included in the RubotoCore platform apk."
        FileUtils.rm_rf g
      end
    end
  else
    Dir.chdir gem_path do
      Dir['jruby-openssl-*/lib'].each do |g|
        rel_dir = "#{g}/lib/ruby"
        unless File.exists? rel_dir
          puts "Relocating #{g} files to match standard load path."
          dirs = Dir["#{g}/*"]
          FileUtils.mkdir_p rel_dir
          dirs.each do |d|
            FileUtils.move d, rel_dir
          end
        end
      end
    end
  end

  # Remove duplicate files
  Dir.chdir gem_path do
    scanned_files = []
    source_files = RUBY_SOURCE_FILES.map { |f| f.gsub("#{PROJECT_DIR}/src/", '') }
    Dir["*/lib/**/*"].each do |f|
      next if File.directory? f
      raise "Malformed file name" unless f =~ %r{^(.*?)/lib/(.*)$}
      gem_name, lib_file = $1, $2
      if existing_file = scanned_files.find { |sf| sf =~ %r{(.*?)/lib/#{lib_file}} }
        puts "Overwriting duplicate file #{lib_file} in gem #{$1} with file in #{gem_name}"
        FileUtils.rm existing_file
        scanned_files.delete existing_file
      elsif source_files.include? lib_file
        puts "Removing duplicate file #{lib_file} in gem #{gem_name}"
        puts "Already present in project source src/#{lib_file}"
        FileUtils.rm f
        next
      end
      scanned_files << f
    end
  end

  # Expand JARs
  Dir.chdir gem_path do
    Dir['*'].each do |gem_lib|
      Dir.chdir "#{gem_lib}/lib" do
        Dir['**/*.jar'].each do |jar|
          if jar == 'arjdbc/jdbc/adapter_java.jar'
            jar_load_code = <<-END_CODE
require 'jruby'
Java::arjdbc.jdbc.AdapterJavaService.new.basicLoad(JRuby.runtime)
            END_CODE
          elsif jar =~ /shared\/jopenssl.jar$/
            jar_load_code = <<-END_CODE
require 'jruby'
puts 'Starting JRuby OpenSSL Service'
public
Java::JopensslService.new.basicLoad(JRuby.runtime)
            END_CODE
          else
            jar_load_code = ''
          end
          unless jar =~ /sqlite-jdbc/
            puts "Expanding #{gem_lib} #{jar} into #{BUNDLE_JAR}"
            `jar xf #{jar}`
          end
          puts "Writing dummy JAR file #{jar + '.rb'}"
          File.open(jar + '.rb', 'w') { |f| f << jar_load_code }
          if jar.end_with?('.jar')
            puts "Writing dummy JAR file #{jar.sub(/.jar$/, '.rb')}"
            File.open(jar.sub(/.jar$/, '.rb'), 'w') { |f| f << jar_load_code }
          end
          FileUtils.rm_f(jar)
        end
      end
    end
  end


  FileUtils.rm_f BUNDLE_JAR
  Dir["#{gem_path}/*"].each_with_index do |gem_dir, i|
    `jar #{i == 0 ? 'c' : 'u'}f #{BUNDLE_JAR} -C #{gem_dir}/lib .`
  end
  FileUtils.rm_rf BUNDLE_PATH
end

# Methods

def mark_update(time = Time.now)
  FileUtils.mkdir_p File.dirname(UPDATE_MARKER_FILE)
  File.open(UPDATE_MARKER_FILE, 'w') { |f| f << time.iso8601 }
end

def clear_update
  mark_update File.ctime APK_FILE
  if device_path_exists?(scripts_path)
    sh "adb shell rm -r #{scripts_path}"
    puts "Deleted scripts directory #{scripts_path}"
  end
end

def strings(name)
  @strings ||= REXML::Document.new(File.read('res/values/strings.xml'))
  value = @strings.elements["//string[@name='#{name.to_s}']"] or raise "string '#{name}' not found in strings.xml"
  value.text
end

def version()
  strings :version_name
end

def app_name()
  strings :app_name
end

def main_activity()
  manifest.root.elements['application'].elements["activity[@android:label='@string/app_name']"].attribute('android:name')
end

def device_path_exists?(path)
  path_output =`adb shell ls #{path}`
  result = path_output.chomp !~ /No such file or directory|opendir failed, Permission denied/
  result
end

def package_installed? test = false
  package_name = "#{package}#{'.tests' if test}"
  ['', '-0', '-1', '-2'].each do |i|
    path = "/data/app/#{package_name}#{i}.apk"
    o = `adb shell ls -l #{path}`.chomp
    if o =~ /^-rw-r--r-- system\s+system\s+(\d+) \d{4}-\d{2}-\d{2} \d{2}:\d{2} #{File.basename(path)}$/
      apk_file = test ? TEST_APK_FILE : APK_FILE
      if !File.exists?(apk_file) || $1.to_i == File.size(apk_file)
        return true
      else
        return false
      end
    end

    sdcard_path = "/mnt/asec/#{package_name}#{i}/pkg.apk"
    o = `adb shell ls -l #{sdcard_path}`.chomp
    if o =~ /^-r-xr-xr-x system\s+root\s+(\d+) \d{4}-\d{2}-\d{2} \d{2}:\d{2} #{File.basename(sdcard_path)}$/
      apk_file = test ? TEST_APK_FILE : APK_FILE
      if !File.exists?(apk_file) || $1.to_i == File.size(apk_file)
        return true
      else
        return false
      end
    end
  end
  return nil
end

def replace_faulty_code(faulty_file, faulty_code)
  explicit_requires = Dir["#{faulty_file.chomp('.rb')}/*.rb"].sort.map { |f| File.basename(f) }.map do |filename|
    "require 'active_model/validations/#{filename}'"
  end.join("\n")

  old_code = File.read(faulty_file)
  new_code = old_code.gsub faulty_code, explicit_requires
  if new_code != old_code
    puts "Replaced directory listing code in file #{faulty_file} with explicit requires."
    File.open(faulty_file, 'w') { |f| f << new_code }
  else
    puts "Could not find expected faulty code\n\n#{faulty_code}\n\nin file #{faulty_file}\n\n#{old_code}\n\n"
  end
end

def build_apk(t, release)
  apk_file = release ? RELEASE_APK_FILE : APK_FILE
  if File.exist?(apk_file)
    changed_prereqs = t.prerequisites.select do |p|
      File.file?(p) && !Dir[p].empty? && Dir[p].map { |f| File.mtime(f) }.max > File.mtime(APK_FILE)
    end
    return false if changed_prereqs.empty?
    changed_prereqs.each { |f| puts "#{f} changed." }
    puts "Forcing rebuild of #{apk_file}."
  end
  if release
    sh 'ant release'
  else
    sh 'ant debug'
  end
  return true
end

def install_apk
  failure_pattern = /^Failure \[(.*)\]/
  success_pattern = /^Success/
  case package_installed?
  when true
    puts "Package #{package} already installed."
    return
  when false
    puts "Package #{package} already installed, but of different size.  Replacing package."
    output = `adb install -r #{APK_FILE} 2>&1`
    if $? == 0 && output !~ failure_pattern && output =~ success_pattern
      clear_update
      return
    end
    case $1
    when 'INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES'
      puts "Found package signed with different certificate.  Uninstalling it and retrying install."
    else
      puts "'adb install' returned an unknown error: (#$?) #{$1 ? "[#$1}]" : output}."
      puts "Uninstalling #{package} and retrying install."
    end
    uninstall_apk
  end
  puts "Installing package #{package}"
  output = `adb install #{APK_FILE} 2>&1`
  puts output
  raise "Install failed (#{$?}) #{$1 ? "[#$1}]" : output}" if $? != 0 || output =~ failure_pattern || output !~ success_pattern
  clear_update
end

def uninstall_apk
  return if package_installed?.nil?
  puts "Uninstalling package #{package}"
  system "adb uninstall #{package}"
  if $? != 0 && package_installed?
    puts "Uninstall failed exit code #{$?}"
    exit $?
  end
end

def update_scripts
  `adb shell mkdir -p #{scripts_path}` if !device_path_exists?(scripts_path)
  puts "Pushing files to apk public file area."
  last_update = File.exists?(UPDATE_MARKER_FILE) ? Time.parse(File.read(UPDATE_MARKER_FILE)) : Time.parse('1970-01-01T00:00:00')
  Dir.chdir('src') do
    Dir["**/*.rb"].each do |script_file|
      next if File.directory? script_file
      next if File.mtime(script_file) < last_update
      next if script_file =~ /~$/
      print "#{script_file}: "; $stdout.flush
      `adb push #{script_file} #{scripts_path}/#{script_file}`
    end
  end
  mark_update
end

def start_app
  `adb shell am start -a android.intent.action.MAIN -n #{package}/.#{main_activity}`
end

def stop_app
  output = `adb shell ps | grep #{package} | awk '{print $2}' | xargs adb shell kill`
  return output !~ /Operation not permitted/
end
