require 'rbconfig'
require 'rubygems'
require 'time'
require 'rake/clean'
require 'rexml/document'
require 'timeout'

ON_WINDOWS = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw/i)

ANT_CMD = ON_WINDOWS ? 'ant.bat' : 'ant'

if `#{ANT_CMD} -version` !~ /version (\d+)\.(\d+)\.(\d+)/ || $1.to_i < 1 || ($1.to_i == 1 && $2.to_i < 8)
  puts "ANT version 1.8.0 or later required.  Version found: #{$1}.#{$2}.#{$3}"
  exit 1
end

adb_version_str = `adb version`
(puts 'Android SDK platform tools not in PATH (adb command not found).'; exit 1) unless $? == 0
(puts "Unrecognized adb version: #$1"; exit 1) unless adb_version_str =~ /Android Debug Bridge version (\d+\.\d+\.\d+)/
(puts "adb version 1.0.31 or later required.  Version found: #$1"; exit 1) unless Gem::Version.new($1) >= Gem::Version.new('1.0.31')
unless ENV['ANDROID_HOME']
  unless ON_WINDOWS
    begin
      adb_path = `which adb`
      ENV['ANDROID_HOME'] = File.dirname(File.dirname(adb_path)) if $? == 0
    rescue Errno::ENOENT
      puts "Unable to detect adb location: #$!"
    end
  end
end
(puts 'You need to set the ANDROID_HOME environment variable.'; exit 1) unless ENV['ANDROID_HOME']

# FIXME(uwe):  On windows the file is called dx.bat
dx_filename = File.join(ENV['ANDROID_HOME'], 'platform-tools', ON_WINDOWS ? 'dx.bat' : 'dx')
unless File.exists? dx_filename
  puts 'You need to install the Android SDK Platform-tools!'
  exit 1
end
new_dx_content = File.read(dx_filename).dup

# FIXME(uwe): Set Xmx on windows bat script:
# set defaultXmx=-Xmx1024M

xmx_pattern = /^defaultMx="-Xmx(\d+)(M|m|G|g|T|t)"/
if new_dx_content =~ xmx_pattern &&
    ($1.to_i * 1024 ** {'M' => 2, 'G' => 3, 'T' => 4}[$2.upcase]) < 2560*1024**2
  puts "Increasing max heap space from #$1#$2 to 2560M in #{dx_filename}"
  new_dx_content.sub!(xmx_pattern, 'defaultMx="-Xmx2560M"')
  File.open(dx_filename, 'w') { |f| f << new_dx_content } rescue puts "\n!!! Unable to increase dx heap size !!!\n\n"
end

def manifest; @manifest ||= REXML::Document.new(File.read(MANIFEST_FILE)) end
def package; manifest.root.attribute('package') end
def build_project_name; @build_project_name ||= REXML::Document.new(File.read('build.xml')).elements['project'].attribute(:name).value end
def scripts_path; @sdcard_path ||= "/mnt/sdcard/Android/data/#{package}/files/scripts" end
def app_files_path; @app_files_path ||= "/data/data/#{package}/files" end

PROJECT_DIR = File.expand_path('..', File.dirname(__FILE__))
UPDATE_MARKER_FILE = File.join(PROJECT_DIR, 'bin', 'LAST_UPDATE')
BUNDLE_JAR = File.expand_path 'libs/bundle.jar'
BUNDLE_PATH = File.expand_path 'bin/bundle'
MANIFEST_FILE = File.expand_path 'AndroidManifest.xml'
PROJECT_PROPS_FILE = File.expand_path 'project.properties'
RUBOTO_CONFIG_FILE = File.expand_path 'ruboto.yml'
GEM_FILE = File.expand_path 'Gemfile.apk'
GEM_LOCK_FILE = "#{GEM_FILE}.lock"
RELEASE_APK_FILE = File.expand_path "bin/#{build_project_name}-release.apk"
APK_FILE = File.expand_path "bin/#{build_project_name}-debug.apk"
TEST_APK_FILE = File.expand_path "test/bin/#{build_project_name}Test-debug.apk"
JRUBY_JARS = Dir[File.expand_path 'libs/jruby-*.jar']
RESOURCE_FILES = Dir[File.expand_path 'res/**/*']
JAVA_SOURCE_FILES = Dir[File.expand_path 'src/**/*.java']
RUBY_SOURCE_FILES = Dir[File.expand_path 'src/**/*.rb']
APK_DEPENDENCIES = [MANIFEST_FILE, RUBOTO_CONFIG_FILE, BUNDLE_JAR] + JRUBY_JARS + JAVA_SOURCE_FILES + RESOURCE_FILES + RUBY_SOURCE_FILES
KEYSTORE_FILE = (key_store = File.readlines('ant.properties').grep(/^key.store=/).first) ? File.expand_path(key_store.chomp.sub(/^key.store=/, '').sub('${user.home}', '~')) : "#{build_project_name}.keystore"
KEYSTORE_ALIAS = (key_alias = File.readlines('ant.properties').grep(/^key.alias=/).first) ? key_alias.chomp.sub(/^key.alias=/, '') : build_project_name

CLEAN.include('bin', 'gen', 'test/bin', 'test/gen')

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

desc 'build package and install it on the emulator or device'
task :install => APK_FILE do
  install_apk
end

desc 'uninstall, build, and install the application'
task :reinstall => [:uninstall, APK_FILE, :install]

namespace :install do
  # FIXME(uwe):  Remove in 2013
  desc 'Deprecated:  use "reinstall" instead.'
  task :clean => :reinstall do
    puts '"rake install:clean" is deprecated.  Use "rake reinstall" instead.'
  end

  desc 'Install the application, but only if compiled files are changed.'
  task :quick => 'debug:quick' do
    install_apk
  end
end

desc 'Build APK for release'
task :release => [:tag, RELEASE_APK_FILE]

file RELEASE_APK_FILE => [KEYSTORE_FILE] + APK_DEPENDENCIES do |t|
  build_apk(t, true)
end

desc 'Create a keystore for signing the release APK'
task :keystore => KEYSTORE_FILE

file KEYSTORE_FILE do
  unless File.read('ant.properties') =~ /^key.store=/
    File.open('ant.properties', 'a') { |f| f << "\nkey.store=#{KEYSTORE_FILE}\n" }
  end
  unless File.read('ant.properties') =~ /^key.alias=/
    File.open('ant.properties', 'a') { |f| f << "\nkey.alias=#{KEYSTORE_ALIAS}\n" }
  end
  sh "keytool -genkey -v -keystore #{KEYSTORE_FILE} -alias #{KEYSTORE_ALIAS} -keyalg RSA -keysize 2048 -validity 10000"
end

desc 'Tag this working copy with the current version'
task :tag do
  next unless File.exists?('.git') && `git --version` =~ /git version /
  unless `git branch` =~ /^\* master$/
    puts 'You must be on the master branch to release!'
    exit!
  end
  # sh "git commit --allow-empty -a -m 'Release #{version}'"
  output = `git status --porcelain`
  raise "\nWorkspace not clean!\n#{output}" unless output.empty?
  sh "git tag #{version}"
  sh 'git push origin master --tags'
end

desc 'Start the emulator with larger disk'
task :emulator do
  start_emulator
end

desc 'Start the application on the device/emulator.'
task :start do
  start_app
end

desc 'Stop the application on the device/emulator (requires emulator or rooted device).'
task :stop do
  raise 'Unable to stop app.  Only available on emulator.' unless stop_app
end

desc 'Restart the application'
task :restart => [:stop, :start]

task :uninstall do
  uninstall_apk
end

file PROJECT_PROPS_FILE
file MANIFEST_FILE => PROJECT_PROPS_FILE do
  old_manifest = File.read(MANIFEST_FILE)
  manifest = old_manifest.dup
  manifest.sub!(/(android:minSdkVersion=').*?(')/) { "#$1#{sdk_level}#$2" }
  manifest.sub!(/(android:targetSdkVersion=').*?(')/) { "#$1#{sdk_level}#$2" }
  File.open(MANIFEST_FILE, 'w') { |f| f << manifest } if manifest != old_manifest
end

file RUBOTO_CONFIG_FILE

file APK_FILE => APK_DEPENDENCIES do |t|
  build_apk(t, false)
end

desc 'Copy scripts to emulator or device'
task :update_scripts => %w(install:quick) do
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

task :test => APK_DEPENDENCIES + [:uninstall] do
  Dir.chdir('test') do
    puts 'Running tests'
    sh "adb uninstall #{package}.tests"
    sh "#{ANT_CMD} instrument install test"
  end
end

namespace :test do
  task :quick => :update_scripts do
    Dir.chdir('test') do
      puts 'Running quick tests'
      sh "#{ANT_CMD} instrument"
      install_retry_count = 0
      begin
        timeout 120 do
          sh "#{ANT_CMD} installi"
        end
      rescue TimeoutError
        puts 'Installing package timed out.'
        install_retry_count += 1
        if install_retry_count <= 3
          puts 'Retrying install...'
          retry
        end
        puts 'Trying one final time to install the package:'
        sh "#{ANT_CMD} installi"
      end
      sh "#{ANT_CMD} run-tests-quick"
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
  require 'bundler'
  require 'bundler/vendored_thor'

  # Store original RubyGems/Bundler environment
  platforms = Gem.platforms
  ruby_engine = defined?(RUBY_ENGINE) && RUBY_ENGINE
  gem_paths = {'GEM_HOME' => Gem.path, 'GEM_PATH' => Gem.dir}

  # Override RUBY_ENGINE (we can bundle from MRI for JRuby)
  Gem.platforms = [Gem::Platform::RUBY, Gem::Platform.new("universal-dalvik-#{sdk_level}"), Gem::Platform.new('universal-java')]
  Gem.paths = {'GEM_HOME' => BUNDLE_PATH, 'GEM_PATH' => BUNDLE_PATH}
  old_verbose, $VERBOSE = $VERBOSE, nil
  begin
    Object.const_set('RUBY_ENGINE', 'jruby')
  ensure
    $VERBOSE = old_verbose
  end

  ENV['BUNDLE_GEMFILE'] = GEM_FILE
  Bundler.ui = Bundler::UI::Shell.new
  Bundler.bundle_path = Pathname.new BUNDLE_PATH
  definition = Bundler.definition
  definition.validate_ruby!
  Bundler::Installer.install(Bundler.root, definition)

  # Restore RUBY_ENGINE (limit the scope of this hack)
  old_verbose, $VERBOSE = $VERBOSE, nil
  begin
    Object.const_set('RUBY_ENGINE', ruby_engine)
  ensure
    $VERBOSE = old_verbose
  end
  Gem.platforms = platforms
  Gem.paths = gem_paths

  gem_paths = Dir["#{BUNDLE_PATH}/gems"]
  raise 'Gem path not found' if gem_paths.empty?
  raise "Found multiple gem paths: #{gem_paths}" if gem_paths.size > 1
  gem_path = gem_paths[0]
  puts "Found gems in #{gem_path}"

  if package != 'org.ruboto.core' && JRUBY_JARS.none? { |f| File.exists? f }
    Dir.chdir gem_path do
      Dir['{activerecord-jdbc-adapter,jruby-openssl}-*'].each do |g|
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
    Dir['*/lib/**/*'].each do |f|
      next if File.directory? f
      raise 'Malformed file name' unless f =~ %r{^(.*?)/lib/(.*)$}
      gem_name, lib_file = $1, $2
      if (existing_file = scanned_files.find { |sf| sf =~ %r{(.*?)/lib/#{lib_file}} })
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
          unless jar =~ /sqlite-jdbc/
            puts "Expanding #{gem_lib} #{jar} into #{BUNDLE_JAR}"
            `jar xf #{jar}`
            if ENV['STRIP_INVOKERS']
              invokers = Dir['**/*$INVOKER$*.class']
              if invokers.size > 0
                puts "Removing invokers(#{invokers.size})..."
                FileUtils.rm invokers
              end
              populators = Dir['**/*$POPULATOR.class']
              if populators.size > 0
                puts "Removing populators(#{populators.size})..."
                FileUtils.rm populators
              end
            end
          end
          if jar == 'arjdbc/jdbc/adapter_java.jar'
            jar_load_code = <<-END_CODE
require 'jruby'
Java::arjdbc.jdbc.AdapterJavaService.new.basicLoad(JRuby.runtime)
            END_CODE

            # TODO(uwe): Seems ARJDBC requires all these classes to be present...
            # classes = Dir['arjdbc/**/*']
            # dbs = /db2|derby|firebird|h2|hsqldb|informix|mimer|mssql|mysql|oracle|postgres|sybase/i
            # files = classes.grep(dbs)
            # FileUtils.rm_f(files)
            # ODOT

            # FIXME(uwe): Extract files with case sensitive names for ARJDBC 1.2.7-1.3.x
            puts `jar xf #{jar} arjdbc/mssql/MSSQLRubyJdbcConnection.class arjdbc/sqlite3/SQLite3RubyJdbcConnection.class`
            # EMXIF

          elsif jar =~ /shared\/jopenssl.jar$/
            jar_load_code = <<-END_CODE
require 'jruby'
puts 'Starting JRuby OpenSSL Service'
public
Java::JopensslService.new.basicLoad(JRuby.runtime)
            END_CODE
          elsif jar =~ %r{json/ext/generator.jar$}
            jar_load_code = <<-END_CODE
require 'jruby'
puts 'Starting JSON Generator Service'
public
Java::json.ext.GeneratorService.new.basicLoad(JRuby.runtime)
            END_CODE
          elsif jar =~ %r{json/ext/parser.jar$}
            jar_load_code = <<-END_CODE
require 'jruby'
puts 'Starting JSON Parser Service'
public
Java::json.ext.ParserService.new.basicLoad(JRuby.runtime)
            END_CODE
          else
            jar_load_code = ''
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

API_LEVEL_TO_VERSION = {
    7 => '2.1', 8 => '2.2', 10 => '2.3.3', 11 => '3.0', 12 => '3.1',
    13 => '3.2', 14 => '4.0', 15 => '4.0.3', 16 => '4.1.2', 17 => '4.2.2',
}

def sdk_level_name
  API_LEVEL_TO_VERSION[sdk_level]
end

def sdk_level
  File.read(PROJECT_PROPS_FILE).scan(/(?:target=android-)(\d+)/)[0][0].to_i
end

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

def version
  manifest.root.attribute('versionName')
end

def app_name
  strings :app_name
end

def main_activity
  manifest.root.elements['application'].elements["activity[@android:label='@string/app_name']"].attribute('android:name')
end

def device_path_exists?(path)
  path_output =`adb shell ls #{path}`
  path_output.chomp !~ /No such file or directory|opendir failed, Permission denied/
end

# Determine if the package is installed.
# Return true if the package is installed and is identical to the local package.
# Return false if the package is installed, but differs from the local package.
# Return nil if the package is not installed.
def package_installed?(test = false)
  package_name = "#{package}#{'.tests' if test}"
  ['', '-0', '-1', '-2'].each do |i|
    path = "/data/app/#{package_name}#{i}.apk"
    o = `adb shell ls -l #{path}`.chomp
    if o =~ /^-rw-r--r-- system\s+system\s+(\d+)\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2})\s+#{File.basename(path)}$/
      installed_apk_size = $1.to_i
      installed_timestamp = Time.parse($2)
      apk_file = test ? TEST_APK_FILE : APK_FILE
      if !File.exists?(apk_file) || (installed_apk_size == File.size(apk_file) &&
          installed_timestamp >= File.mtime(apk_file))
        return true
      else
        return false
      end
    end

    sdcard_path = "/mnt/asec/#{package_name}#{i}/pkg.apk"
    o = `adb shell ls -l #{sdcard_path}`.chomp
    if o =~ /^-r-xr-xr-x system\s+root\s+(\d+)\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2})\s+#{File.basename(sdcard_path)}$/
      installed_apk_size = $1.to_i
      installed_timestamp = Time.parse($2)
      apk_file = test ? TEST_APK_FILE : APK_FILE
      if !File.exists?(apk_file) || (installed_apk_size == File.size(apk_file) &&
          installed_timestamp >= File.mtime(apk_file))
        return true
      else
        return false
      end
    end
  end
  nil
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
    sh "#{ANT_CMD} release"
  else
    sh "#{ANT_CMD} debug"
  end
  true
end

def install_apk
  failure_pattern = /^Failure \[(.*)\]/
  success_pattern = /^Success/
  case package_installed?
  when true
    puts "Package #{package} already installed."
    return
  when false
    puts "Package #{package} already installed, but of different size or timestamp.  Replacing package."
    sh "adb shell date -s #{Time.now.strftime '%Y%m%d.%H%M%S'}"
    output = nil
    install_retry_count = 0
    begin
      timeout 120 do
        output = `adb install -r "#{APK_FILE}" 2>&1`
      end
    rescue Timeout::Error
      puts "Installing package #{package} timed out."
      install_retry_count += 1
      if install_retry_count <= 3
        puts 'Retrying install...'
        retry
      end
      puts 'Trying one final time to install the package:'
      output = `adb install -r "#{APK_FILE}" 2>&1`
    end
    if $? == 0 && output !~ failure_pattern && output =~ success_pattern
      clear_update
      return
    end
    case $1
    when 'INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES'
      puts 'Found package signed with different certificate.  Uninstalling it and retrying install.'
    else
      puts "'adb install' returned an unknown error: (#$?) #{$1 ? "[#$1}]" : output}."
      puts "Uninstalling #{package} and retrying install."
    end
    uninstall_apk
  else
    # Package not installed.
    sh "adb shell date -s #{Time.now.strftime '%Y%m%d.%H%M%S'}"
  end
  puts "Installing package #{package}"
  output = nil
  install_retry_count = 0
  begin
    timeout 120 do
      output = `adb install "#{APK_FILE}" 2>&1`
    end
  rescue Timeout::Error
    puts "Installing package #{package} timed out."
    install_retry_count += 1
    if install_retry_count <= 3
      puts 'Retrying install...'
      retry
    end
    puts 'Trying one final time to install the package:'
    output = `adb install "#{APK_FILE}" 2>&1`
  end
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
  puts 'Pushing files to apk public file area.'
  last_update = File.exists?(UPDATE_MARKER_FILE) ? Time.parse(File.read(UPDATE_MARKER_FILE)) : Time.parse('1970-01-01T00:00:00')
  Dir.chdir('src') do
    Dir['**/*.rb'].each do |script_file|
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
  output !~ /Operation not permitted/
end

def start_emulator
  STDOUT.sync = true
  # FIXME(uwe):  Use RBConfig instead
  if `uname -m`.chomp == 'x86_64'
    emulator_cmd = 'emulator64-arm'
  else
    emulator_cmd = 'emulator-arm'
  end
  
  emulator_opts = '-partition-size 256'
  if ENV['DISPLAY'].nil?
    emulator_opts << ' -no-window -no-audio'
  end

  avd_name = "Android_#{sdk_level_name}"
  new_snapshot = false
  loop do
    `killall -0 #{emulator_cmd} 2> /dev/null`
    if $? == 0
      `killall #{emulator_cmd}`
      10.times do |i|
        `killall -0 #{emulator_cmd} 2> /dev/null`
        if $? != 0
          break
        end
        if i == 3
          print 'Waiting for emulator to die: ...'
        elsif i > 3
          print '.'
        end
        sleep 1
      end
      puts
      `killall -0 #{emulator_cmd} 2> /dev/null`
      if $? == 0
        puts 'Emulator still running.'
        `killall -9 #{emulator_cmd}`
        sleep 1
      end
    end

    if [17, 16, 15, 13, 11].include? sdk_level
      abi_opt = '--abi armeabi-v7a'
    elsif sdk_level == 10
      abi_opt = '--abi armeabi'
    end

    unless File.exists? "#{ENV['HOME']}/.android/avd/#{avd_name}.avd"
      puts "Creating AVD #{avd_name}"
      heap_size = (File.read('AndroidManifest.xml') =~ /largeHeap/) ? 256 : 48
      # FIXME(uwe):  Use Ruby instead.
      # FIXME(uwe):  Only change the heap size to be larger.
      # `sed -i.bak -e "s/vm.heapSize=[0-9]*/vm.heapSize=#{heap_size}/" #{ENV['ANDROID_HOME']}/platforms/*/*/*/hardware.ini`
      `echo n | android create avd -a -n #{avd_name} -t android-#{sdk_level} #{abi_opt} -c 64M -s HVGA`
      `sed -i.bak -e "s/vm.heapSize=[0-9]*/vm.heapSize=#{heap_size}/" #{ENV['HOME']}/.android/avd/#{avd_name}.avd/config.ini`
      new_snapshot = true
    end
  
    puts 'Start emulator'
    system "emulator -avd #{avd_name} #{emulator_opts} &"
  
    3.times do |i|
      sleep 1
      `killall -0 #{emulator_cmd} 2> /dev/null`
      if $? == 0
        break
      end
      if i == 3
        print 'Waiting for emulator: ...'
      elsif i > 3
          print '.'
      end
    end
    puts
    `killall -0 #{emulator_cmd} 2> /dev/null`
    if $? != 0
      puts 'Unable to start the emulator.  Retrying without loading snapshot.'
      system "emulator -no-snapshot-load -avd #{avd_name} #{emulator_opts} &"
      10.times do |i|
        `killall -0 #{emulator_cmd} 2> /dev/null`
        if $? == 0
          new_snapshot = true
          break
        end
        if i == 3
          print 'Waiting for emulator: ...'
        elsif i > 3
            print '.'
        end
        sleep 1
      end
    end
  
    `killall -0 #{emulator_cmd} 2> /dev/null`
    if $? == 0
      print 'Emulator started: '
      50.times do
        if `adb get-state`.chomp == 'device'
          break
        end
        print '.'
        sleep 1
      end
      puts
      if `adb get-state`.chomp == 'device'
        break
      end
    end
    puts 'Unable to start the emulator.'
  end

  if new_snapshot
    puts 'Allow the emulator to calm down a bit.'
    sleep 15
  end
  
  system '(
    set +e
    for i in 1 2 3 4 5 6 7 8 9 10 ; do
      sleep 6
      adb shell input keyevent 82 >/dev/null 2>&1
      if [ "$?" == "0" ] ; then
        set -e
        adb shell input keyevent 82 >/dev/null 2>&1
        adb shell input keyevent 4 >/dev/null 2>&1
        exit 0
      fi
    done
    echo "Failed to unlock screen"
    set -e
    exit 1
  ) &'
  
  system 'adb logcat > adb_logcat.log &'
  
  puts "Emulator #{avd_name} started OK."
end
