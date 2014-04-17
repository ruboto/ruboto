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

#
# OS independent "which"
# From: http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
#
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].gsub('\\', '/').split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable? exe
    end
  end
  nil
end

adb_version_str = `adb version`
(puts 'Android SDK platform tools not in PATH (adb command not found).'; exit 1) unless $? == 0
(puts "Unrecognized adb version: #$1"; exit 1) unless adb_version_str =~ /Android Debug Bridge version (\d+\.\d+\.\d+)/
(puts "adb version 1.0.31 or later required.  Version found: #$1"; exit 1) unless Gem::Version.new($1) >= Gem::Version.new('1.0.31')
android_home = ENV['ANDROID_HOME']
if android_home.nil?
  if (adb_path = which('adb'))
    android_home = File.dirname(File.dirname(adb_path))
    ENV['ANDROID_HOME'] = android_home
  else
    abort 'You need to set the ANDROID_HOME environment variable.'
  end
else
  android_home = android_home.gsub('\\', '/')
end

# FIXME(uwe): Simplify when we stop supporting Android SDK < 22: Don't look in platform-tools for dx
DX_FILENAME = Dir[File.join(android_home, '{build-tools/*,platform-tools}', ON_WINDOWS ? 'dx.bat' : 'dx')][-1]
# EMXIF

unless DX_FILENAME
  puts 'You need to install the Android SDK Build-tools!'
  exit 1
end

def manifest
  @manifest ||= REXML::Document.new(File.read(MANIFEST_FILE))
end

def package
  manifest.root.attribute('package')
end

def build_project_name
  @build_project_name ||= REXML::Document.new(File.read('build.xml')).elements['project'].attribute(:name).value
end

def scripts_path
  @sdcard_path ||= "/mnt/sdcard/Android/data/#{package}/files/scripts"
end

def app_files_path
  @app_files_path ||= "/data/data/#{package}/files"
end

PROJECT_DIR = File.expand_path('..', File.dirname(__FILE__))
UPDATE_MARKER_FILE = File.join(PROJECT_DIR, 'bin', 'LAST_UPDATE')
BUNDLE_JAR = File.expand_path 'libs/bundle.jar'
BUNDLE_PATH = File.join(PROJECT_DIR, 'bin', 'bundle')
MANIFEST_FILE = File.expand_path 'AndroidManifest.xml'
PROJECT_PROPS_FILE = File.expand_path 'project.properties'
RUBOTO_CONFIG_FILE = File.expand_path 'ruboto.yml'
GEM_FILE = File.expand_path 'Gemfile.apk'
GEM_LOCK_FILE = "#{GEM_FILE}.lock"
RELEASE_APK_FILE = File.expand_path "bin/#{build_project_name}-release.apk"
APK_FILE = File.expand_path "bin/#{build_project_name}-debug.apk"
TEST_APK_FILE = File.expand_path "test/bin/#{build_project_name}Test-debug.apk"
JRUBY_JARS = Dir[File.expand_path 'libs/{jruby-*,dx}.jar']
JARS = Dir[File.expand_path 'libs/*.jar'] - JRUBY_JARS
RESOURCE_FILES = Dir[File.expand_path 'res/**/*']
JAVA_SOURCE_FILES = Dir[File.expand_path 'src/**/*.java']
RUBY_SOURCE_FILES = Dir[File.expand_path 'src/**/*.rb']
OTHER_SOURCE_FILES = Dir[File.expand_path 'src/**/*'] - JAVA_SOURCE_FILES - RUBY_SOURCE_FILES
CLASSES_CACHE = "#{PROJECT_DIR}/bin/#{build_project_name}-debug-unaligned.apk.d"
APK_DEPENDENCIES = [:patch_dex, MANIFEST_FILE, RUBOTO_CONFIG_FILE, BUNDLE_JAR, CLASSES_CACHE] + JRUBY_JARS + JARS + JAVA_SOURCE_FILES + RESOURCE_FILES + RUBY_SOURCE_FILES + OTHER_SOURCE_FILES
KEYSTORE_FILE = (key_store = File.readlines('ant.properties').grep(/^key.store=/).first) ? File.expand_path(key_store.chomp.sub(/^key.store=/, '').sub('${user.home}', '~')) : "#{build_project_name}.keystore"
KEYSTORE_ALIAS = (key_alias = File.readlines('ant.properties').grep(/^key.alias=/).first) ? key_alias.chomp.sub(/^key.alias=/, '') : build_project_name
APK_FILE_REGEXP = /^-rw-r--r--\s+(?:system|\d+\s+\d+)\s+(?:system|\d+)\s+(\d+)\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}|\w{3} \d{2}\s+(?:\d{4}|\d{2}:\d{2}))\s+(.*)$/
JRUBY_ADAPTER_FILE = "#{PROJECT_DIR}/src/org/ruboto/JRubyAdapter.java"

CLEAN.include('bin', 'gen', 'test/bin', 'test/gen')

task :default => :debug

if File.exists?(CLASSES_CACHE)
  expected_jars = File.readlines(CLASSES_CACHE).grep(%r{#{PROJECT_DIR}/libs/(.*\.jar) \\}).map { |l| l =~ %r{#{PROJECT_DIR}/libs/(.*\.jar) \\}; $1 }
  actual_jars = Dir['libs/*.jar'].map { |f| f =~ /libs\/(.*\.jar)/; $1 }
  changed_jars = ((expected_jars | actual_jars) - (expected_jars & actual_jars))
  unless changed_jars.empty?
    puts "Jars have changed: #{changed_jars.join(', ')}"
    FileUtils.touch(CLASSES_CACHE)
  end
end

file CLASSES_CACHE

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
  task :quick => APK_DEPENDENCIES - RUBY_SOURCE_FILES do |t|
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
  # FIXME(uwe):  Remove December 2013
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

# FIXME(uwe):  Remove December 2013
desc 'Deprecated:  Use "ruboto emulator" instead.'
task :emulator do
  puts '"rake emulator" is deprecated.  Use "ruboto emulator" instead.'
  sh 'ruboto emulator'
end
# EMXIF

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
  if manifest != old_manifest
    puts "\nUpdating #{File.basename MANIFEST_FILE} with target from #{File.basename PROJECT_PROPS_FILE}\n\n"
    File.open(MANIFEST_FILE, 'w') { |f| f << manifest }
  end
end

file RUBOTO_CONFIG_FILE

task :jruby_adapter => JRUBY_ADAPTER_FILE
file JRUBY_ADAPTER_FILE => RUBOTO_CONFIG_FILE do
  require 'yaml'

  ruboto_yml = (YAML.load(File.read(RUBOTO_CONFIG_FILE)) || {})
  source = File.read(JRUBY_ADAPTER_FILE)

  #
  # HeapAlloc
  #
  comment = ''
  marker_topic ='Ruboto HeapAlloc'
  begin_marker = "// BEGIN #{marker_topic}"
  end_marker = "// END #{marker_topic}"
  unless (heap_alloc = ruboto_yml['heap_alloc'])
    heap_alloc = 13
    comment = '// '
  end
  config = <<EOF
            #{begin_marker}
            #{comment}@SuppressWarnings("unused")
            #{comment}byte[] arrayForHeapAllocation = new byte[#{heap_alloc} * 1024 * 1024];
            #{comment}arrayForHeapAllocation = null;
            #{end_marker}
EOF
  pattern = %r{^\s*#{begin_marker}\n.*^\s*#{end_marker}\n}m
  source = source.sub(pattern, config)

  #
  # RubyVersion
  #
  comment = ''
  marker_topic ='Ruboto RubyVersion'
  begin_marker = "// BEGIN #{marker_topic}"
  end_marker = "// END #{marker_topic}"
  unless (ruby_version = ruboto_yml['ruby_version'])
    ruby_version = 2.0
    comment = '// '
  end
  ruby_version = ruby_version.to_s
  ruby_version['.'] = '_'
  config = <<EOF
            #{begin_marker}
            #{comment}System.setProperty("jruby.compat.version", "RUBY#{ruby_version}"); // RUBY1_9 is the default in JRuby 1.7
            #{end_marker}
EOF
  pattern = %r{^\s*#{begin_marker}\n.*^\s*#{end_marker}\n}m
  source = source.sub(pattern, config)

  File.open(JRUBY_ADAPTER_FILE, 'w') { |f| f << source }
end

file APK_FILE => APK_DEPENDENCIES do |t|
  build_apk(t, false)
end

MINIMUM_DX_HEAP_SIZE = 2048
task :patch_dex do
  new_dx_content = File.read(DX_FILENAME).dup
  xmx_pattern = ON_WINDOWS ? /^set defaultXmx=-Xmx(\d+)(M|m|G|g|T|t)/ : /^defaultMx="-Xmx(\d+)(M|m|G|g|T|t)"/
  if new_dx_content =~ xmx_pattern &&
      ($1.to_i * 1024 ** {'M' => 2, 'G' => 3, 'T' => 4}[$2.upcase]) < MINIMUM_DX_HEAP_SIZE*1024**2
    puts "Increasing max heap space from #$1#$2 to #{MINIMUM_DX_HEAP_SIZE}M in #{DX_FILENAME}"
    new_xmx_value = ON_WINDOWS ? %Q{set defaultXmx=-Xmx#{MINIMUM_DX_HEAP_SIZE}M} : %Q{defaultMx="-Xmx#{MINIMUM_DX_HEAP_SIZE}M"}
    new_dx_content.sub!(xmx_pattern, new_xmx_value)
    File.open(DX_FILENAME, 'w') { |f| f << new_dx_content } rescue puts "\n!!! Unable to increase dx heap size !!!\n\n"
  end
end

desc 'Copy scripts to emulator or device'
task :update_scripts => %w(install:quick) do
  update_scripts
end

desc 'Copy scripts to emulator or device and reload'
task :boing => %w(update_scripts:reload)

namespace :update_scripts do
  desc 'Copy scripts to emulator and restart the app'
  task :restart => APK_DEPENDENCIES - RUBY_SOURCE_FILES do |t|
    if build_apk(t, false) || !stop_app
      install_apk
    else
      update_scripts
    end
    start_app
  end

  desc 'Copy scripts to emulator and restart the app'
  task :start => APK_DEPENDENCIES - RUBY_SOURCE_FILES do |t|
    if build_apk(t, false)
      install_apk
    else
      update_scripts
    end
    start_app
  end

  desc 'Copy scripts to emulator and reload'
  task :reload => APK_DEPENDENCIES - RUBY_SOURCE_FILES do |t|
    if build_apk(t, false)
      install_apk
      start_app
    else
      scripts = update_scripts
      if scripts
        if app_running?
          reload_scripts(scripts)
        else
          start_app
        end
      end
    end
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
      install_retry_count = 0
      begin
        timeout 120 do
          sh "#{ANT_CMD} instrument install"
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
  # FIXME(uwe): Issue #547 https://github.com/ruboto/ruboto/issues/547
  if true || Gem::Version.new(Bundler::VERSION) <= Gem::Version.new('1.6.3')
    require 'bundler/vendored_thor'

    # Store original RubyGems/Bundler environment
    platforms = Gem.platforms
    ruby_engine = defined?(RUBY_ENGINE) && RUBY_ENGINE
    env_home = ENV['GEM_HOME']
    env_path = ENV['GEM_PATH']

    # Override RUBY_ENGINE (we can bundle from MRI for JRuby)
    Gem.platforms = [Gem::Platform::RUBY, Gem::Platform.new("universal-dalvik-#{sdk_level}"), Gem::Platform.new('universal-java')]
    ENV['GEM_HOME'] = BUNDLE_PATH
    ENV['GEM_PATH'] = BUNDLE_PATH
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
    unless Dir["#{BUNDLE_PATH}/bundler/gems/"].empty?
      system("mkdir -p '#{BUNDLE_PATH}/gems'")
      system("mv #{BUNDLE_PATH}/bundler/gems/* #{BUNDLE_PATH}/gems/")
    end

    # Restore RUBY_ENGINE (limit the scope of this hack)
    old_verbose, $VERBOSE = $VERBOSE, nil
    begin
      Object.const_set('RUBY_ENGINE', ruby_engine)
    ensure
      $VERBOSE = old_verbose
    end
    Gem.platforms = platforms
    ENV['GEM_HOME'] = env_home
    ENV['GEM_PATH'] = env_path
  else
    # Bundler.settings[:platform] = Gem::Platform::DALVIK
    sh "bundle install --gemfile #{GEM_FILE} --path=#{BUNDLE_PATH} --platform=dalvik#{sdk_level}"
  end

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
            puts `jar xf #{jar} arjdbc/postgresql/PostgreSQLRubyJdbcConnection.class arjdbc/mssql/MSSQLRubyJdbcConnection.class arjdbc/sqlite3/SQLite3RubyJdbcConnection.class`
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
    `jar #{i == 0 ? 'c' : 'u'}f "#{BUNDLE_JAR}" -C "#{gem_dir}/lib" .`
  end
  FileUtils.rm_rf BUNDLE_PATH
end

desc 'Log activity execution, accepts optional logcat filter'
task :log, [:filter] do |t, args|
  puts '--- clearing logcat'
  `adb logcat -c`
  filter = args[:filter] ? args[:filter] : '' # filter log with filter-specs like TAG:LEVEL TAG:LEVEL ... '*:S'
  logcat_cmd = "adb logcat ActivityManager #{filter}" # we always need ActivityManager logging to catch activity start
  puts "--- starting logcat: #{logcat_cmd}"
  IO.popen logcat_cmd do |logcat|
    puts "--- waiting for activity #{package}/.#{main_activity} ..."
    activity_started = false
    started_regex = Regexp.new "^\\I/ActivityManager.+Start proc #{package} for activity #{package}/\\.#{main_activity}: pid=(?<pid>\\d+)"
    restarted_regex = Regexp.new "^\\I/ActivityManager.+START u0 {cmp=#{package}/org.ruboto.RubotoActivity.+} from pid (?<pid>\\d+)"
    related_regex = Regexp.new "#{package}|#{main_activity}"
    pid_regex = nil
    logcat.each_line do |line|
      if (activity_start_match = started_regex.match(line) || restarted_regex.match(line))
        activity_started = true
        pid = activity_start_match[:pid]
        pid_regex = Regexp.new "\\( *#{pid}\\): "
        puts "--- activity PID=#{pid}"
      end
      if activity_started && (line =~ pid_regex || line =~ related_regex)
        puts "#{Time.now.strftime('%Y%m%d %H%M%S.%6N')} #{line}"
      end
    end
    puts '--- logcat closed'
  end
end

# Methods

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
  loop do
    path_line = `adb shell pm path #{package_name}`.chomp
    path_line.gsub! /^WARNING:.*$/, ''
    return nil if $? == 0 && path_line.empty?
    break if $? == 0 && path_line =~ /^package:(.*)$/
    puts path_line
    sleep 0.5
  end
  path = $1
  o = `adb shell ls -l #{path}`.chomp
  raise "Unexpected ls output: #{o}" if o !~ APK_FILE_REGEXP
  installed_apk_size = $1.to_i
  installed_timestamp = Time.parse($2)
  apk_file = test ? TEST_APK_FILE : APK_FILE
  !File.exists?(apk_file) || (installed_apk_size == File.size(apk_file) &&
      installed_timestamp >= File.mtime(apk_file))
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
    changed_prereqs = t.prerequisites.select do |pr|
      File.file?(pr) && !Dir[pr].empty? && Dir[pr].map { |f| File.mtime(f) }.max >= File.mtime(apk_file)
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

def wait_for_valid_device
  while `adb shell echo "ping"`.strip != 'ping'
    `adb kill-server`
    `adb devices`
    sleep 5
  end
end

def install_apk
  wait_for_valid_device

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
  puts(`adb shell mkdir -p #{scripts_path}`) unless device_path_exists?(scripts_path)
  raise "Unable to create device scripts dir: #{scripts_path}" unless device_path_exists?(scripts_path)
  last_update = File.exists?(UPDATE_MARKER_FILE) ? Time.parse(File.read(UPDATE_MARKER_FILE)) : Time.parse('1970-01-01T00:00:00')
  Dir.chdir('src') do
    source_files = Dir['**/*.rb']
    changed_files = source_files.select { |f| !File.directory?(f) && File.mtime(f) >= last_update && f !~ /~$/ }
    unless changed_files.empty?
      puts 'Pushing files to apk public file area.'
      changed_files.each do |script_file|
        print "#{script_file}: "; $stdout.flush
        `adb push #{script_file} #{scripts_path}/#{script_file}`
      end
      mark_update
      return changed_files
    end
  end
  return nil
end

def app_running?
  `adb shell ps | egrep -e " #{package}\r$"`.size > 0
end

def start_app
  `adb shell am start -a android.intent.action.MAIN -n #{package}/.#{main_activity}`
end

# Triggers reload of updated scripts and restart of the current activity
def reload_scripts(scripts)
  s = scripts.map{|s| s.gsub(/[&;]/){|m| "&#{m[0]}"}}.join('\;')
  cmd = %Q{adb shell am broadcast -a android.intent.action.VIEW -e reload '#{s}'}
  puts cmd
  system cmd
end

def stop_app
  output = `adb shell ps | grep #{package} | awk '{print $2}' | xargs adb shell kill`
  output !~ /Operation not permitted/
end
