$:.unshift('lib') unless $:.include?('lib')
require 'test/unit'
require 'rubygems'
require 'fileutils'
require 'yaml'
require 'ruboto/sdk_versions'

module RubotoTest
  include Ruboto::SdkVersions

  PROJECT_DIR = File.expand_path('..', File.dirname(__FILE__))
  $LOAD_PATH << PROJECT_DIR

  GEM_PATH = File.join PROJECT_DIR, 'tmp', 'gems'
  FileUtils.mkdir_p GEM_PATH
  ENV['GEM_HOME'] = GEM_PATH
  ENV['GEM_PATH'] = GEM_PATH
  ENV['PATH'] = "#{GEM_PATH}/bin:#{ENV['PATH']}"
  Gem.paths = GEM_PATH
  Gem.refresh
  `gem query -i -n bundler`
  system 'gem install bundler --no-ri --no-rdoc' unless $? == 0
  `bundle check`
  system 'bundle --system' unless $? == 0
  lib_path = File.expand_path('lib', File.dirname(File.dirname(__FILE__)))
  $LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)
  require 'ruboto'
  require 'ruboto/version'

  PACKAGE = 'org.ruboto.test_app'
  APP_NAME = 'RubotoTestApp'
  TMP_DIR = File.join PROJECT_DIR, 'tmp'
  APP_DIR = File.join TMP_DIR, APP_NAME
  ANDROID_TARGET = (ENV['ANDROID_TARGET'] && ENV['ANDROID_TARGET'].slice(/\d+/).to_i) || MINIMUM_SUPPORTED_SDK_LEVEL
  VERSION_TO_API_LEVEL = {
      '2.1' => 'android-7', '2.1-update1' => 'android-7', '2.2' => 'android-8',
      '2.3' => 'android-9', '2.3.1' => 'android-9', '2.3.2' => 'android-9',
      '2.3.3' => 'android-10', '2.3.4' => 'android-10',
      '3.0' => 'android-11', '3.1' => 'android-12', '3.2' => 'android-13',
      '4.0.1' => 'android-14', '4.0.3' => 'android-15', '4.0.4' => 'android-15',
      '4.1' => 'android-16', '4.1.1' => 'android-16'
  }

  def self.version_from_device
    puts "Reading OS version from device/emulator"
    system "adb wait-for-device"
    IO.popen('adb bugreport').each_line do |line|
      if line =~ /sdk-eng (.*?) .*? .*? test-keys/
        version = $1
        api_level = VERSION_TO_API_LEVEL[version]
        raise "Unknown version: #{version}" if api_level.nil?
        return api_level
      end
      if line =~ /\[ro\.build\.version\.sdk\]: \[(\d+)\]/
        return $1
      end
    end
    raise "Unable to read device/emulator apilevel"
  end

  def self.install_jruby_jars_gem
    jars_version_from_env = ENV['JRUBY_JARS_VERSION']
    version_requirement = "-v #{jars_version_from_env}" if jars_version_from_env
    `gem query -i -n jruby-jars #{version_requirement}`
    system "gem install #{jars_version_from_env.nil? || !File.exists?("jruby-jars-#{jars_version_from_env}.gem") ? '-r' : '-l'} jruby-jars #{version_requirement} --no-ri --no-rdoc" unless $? == 0
    raise "install of jruby-jars failed with return code #$?" unless $? == 0
    if jars_version_from_env
      exclusion_clause = %Q{-v "!=#{jars_version_from_env}"}
      `gem query -i -n jruby-jars #{exclusion_clause}`
      if $? == 0
        system %Q{gem uninstall jruby-jars --all #{exclusion_clause}}
        raise "Uninstall of jruby-jars failed with return code #$?" unless $? == 0
      end
    end
    Gem.refresh
  end

  def install_jruby_jars_gem
    RubotoTest::install_jruby_jars_gem
  end

  def uninstall_jruby_jars_gem
    `gem query --no-installed -n jruby-jars`
    system 'gem uninstall jruby-jars --all' if $? != 0
    assert_equal 0, $?, "uninstall of jruby-jars failed with return code #$?"
  end

  def install_ruboto_gem(version)
    version_requirement = "-v #{version}"
    `gem query -i -n ^ruboto$ #{version_requirement}`
    system "gem install ruboto #{version_requirement} --no-ri --no-rdoc" unless $? == 0
    raise "install of ruboto #{version} failed with return code #$?" unless $? == 0
  end

  puts RUBY_DESCRIPTION

  ANDROID_OS = (ENV['ANDROID_OS'] || version_from_device).slice(/\d+/).to_i
  puts "ANDROID_OS: #{ANDROID_OS}"
  puts "ANDROID_TARGET: #{ANDROID_TARGET}"

  RUBOTO_CMD = "ruby -rubygems -I #{PROJECT_DIR}/lib #{PROJECT_DIR}/bin/ruboto"

  puts "ANDROID_HOME: #{ANDROID_HOME}"
  puts "ANDROID_SDK_TOOLS_REVISION: #{ANDROID_TOOLS_REVISION}"

  install_jruby_jars_gem

  # FIXME(uwe):  Simplify when we stop supporting rubygems < 1.8.0
  if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
    gem_spec = Gem::Specification.find_by_path 'jruby-jars'
  else
    gem_spec = Gem.searcher.find('jruby-jars')
  end
  # FIXME end

  raise StandardError.new("Can't find Gem specification jruby-jars.") unless gem_spec
  JRUBY_JARS_VERSION = gem_spec.version
  puts "JRUBY_JARS_VERSION: #{JRUBY_JARS_VERSION}"

  RUBOTO_PLATFORM = ENV['RUBOTO_PLATFORM'] || 'CURRENT'
  puts "RUBOTO_PLATFORM: #{RUBOTO_PLATFORM}"
end

class Test::Unit::TestCase
  include RubotoTest
  extend RubotoTest

  alias old_run run

  def run(*args, &block)
    mark_test_start("#{self.class.name}\##{respond_to?(:method_name) ? method_name : __name__}")
    old_run(*args, &block)
    mark_test_end("#{self.class.name}\##{respond_to?(:method_name) ? method_name : __name__}")
  end

  def mark_test_start(test_name)
    @start_time = Time.now
    log
    log '=' * 80
    log "Starting test #{test_name} at #{@start_time.strftime('%Y-%m-%d %H:%M:%S')}:"
    log
  end

  def mark_test_end(test_name)
    log
    duration = (Time.now - @start_time).to_i
    log "Ended test #{test_name}: #{passed? ? 'PASSED' : 'FAILED'} after #{duration / 60}:#{'%02d' % (duration % 60)}"
    log '=' * 80
    log
  end

  def log(message = '')
    puts message
    `adb shell log -t 'RUBOTO TEST' '#{message}'`
  end

  def generate_app(options = {})
    example = options.delete(:example) || false
    update = options.delete(:update) || false
    excluded_stdlibs = options.delete(:excluded_stdlibs)
    standalone = options.delete(:standalone) || !!excluded_stdlibs || ENV['RUBOTO_PLATFORM'] == 'STANDALONE'
    raise "Unknown options: #{options.inspect}" unless options.empty?
    Dir.mkdir TMP_DIR unless File.exists? TMP_DIR

    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
    template_dir = "#{APP_DIR}_template_#{$$}"
    template_dir << "_example_#{example}" if example
    template_dir << '_updated' if update
    template_dir << '_standalone' if standalone
    template_dir << "_without_#{excluded_stdlibs.map { |ed| ed.gsub(/[.\/]/, '_') }.join('_')}" if excluded_stdlibs
    if File.exists?(template_dir)
      puts "Copying app from template #{template_dir}"
      FileUtils.cp_r template_dir, APP_DIR, :preserve => true
    else
      install_jruby_jars_gem

      if example
        Dir.chdir TMP_DIR do
          system "tar xzf #{PROJECT_DIR}/examples/#{APP_NAME}_#{example}.tgz"
        end
        Dir.chdir APP_DIR do
          File.open('local.properties', 'w') { |f| f.puts "sdk.dir=#{ANDROID_HOME}" }
          File.open('test/local.properties', 'w') { |f| f.puts "sdk.dir=#{ANDROID_HOME}" }
          if standalone
            exclude_stdlibs(excluded_stdlibs) if excluded_stdlibs
            FileUtils.touch 'libs/jruby-core-x.x.x.jar'
            FileUtils.touch 'libs/jruby-stdlib-x.x.x.jar'
          else
            FileUtils.rm(Dir['libs/{jruby-*.jar,dexmaker*.jar}'])
          end
          update_app if update
        end
      else
        uninstall_jruby_jars_gem unless standalone
        puts "Generating app #{APP_DIR}"
        system "#{RUBOTO_CMD} gen app --package #{PACKAGE} --path #{APP_DIR} --name #{APP_NAME} --target android-#{ANDROID_TARGET}"
        if $? != 0
          FileUtils.rm_rf APP_DIR
          raise "gen app failed with return code #$?"
        end
        if standalone
          Dir.chdir APP_DIR do
            exclude_stdlibs(excluded_stdlibs) if excluded_stdlibs
            system "#{RUBOTO_CMD} update jruby --force"
            raise "update jruby failed with return code #$?" if $? != 0
          end
        end
      end

      # FIXME(uwe): Installation with dexmaker fails on Android < 4.0.3 due to complex interface structure
      # Fixme(uwe): Remove when solved
      if standalone && ANDROID_OS < 15
        Dir.chdir APP_DIR do
          puts "Removing dexmaker jar for android-#{ANDROID_OS}"
          FileUtils.rm(Dir['libs/dexmaker*.jar'])
        end
      end
      # FIXME end

      unless example && !update
        Dir.chdir APP_DIR do
          system 'rake debug'
          assert_equal 0, $?
        end
      end
      puts "Storing app as template #{template_dir}"
      FileUtils.cp_r APP_DIR, template_dir, :preserve => true
    end
  end

  def update_app
    system "#{RUBOTO_CMD} update app"
    assert_equal 0, $?, "update app failed with return code #$?"
  end

  def cleanup_app
    # FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end

  def run_app_tests
    if [7, 8].include? ANDROID_OS
      puts "Skipping instrumentation tests on #{ANDROID_OS} since they don't work."
      return
    end
    check_platform_installation(Dir['libs/jruby-core-*.jar'].any?)
    Dir.chdir APP_DIR do
      # FIXME(uwe): Simplify when we stop supporting JRuby < 1.7.0
      if RUBOTO_PLATFORM == 'CURRENT' || JRUBY_JARS_VERSION =~ /^1\.(6\.|7\.0\.(dev|preview))/
        puts "Ruboto platform #{RUBOTO_PLATFORM} and JRuby #{JRUBY_JARS_VERSION} detected.  Running test with retries for ArrayIndexOutOfBoundsException"
        loop do
          output = `rake test:quick`
          puts output
          break if $? == 0 || output !~ /INSTRUMENTATION_RESULT: longMsg=java.lang.ArrayIndexOutOfBoundsException/
          puts 'Known ArrayIndexOutOfBoundsException failure detected.  Retrying.'
        end
        assert_equal 0, $?, "tests failed with return code #$?"
      else
        system 'rake test:quick'
        assert_equal 0, $?, "tests failed with return code #$?"
      end
    end
  end

  def check_platform_installation(standalone)
    if standalone
      system 'rake platform:uninstall'
    else
      if RUBOTO_PLATFORM == 'CURRENT'
        system "rake platform:current platform:install"
      elsif RUBOTO_PLATFORM == 'FROM_GEM'
        system "rake platform:debug platform:install"
      end
    end
    if $? != 0
      FileUtils.rm_rf 'tmp/RubotoCore'
      fail 'Error (un)installing RubotoCore'
    end
  end

  def exclude_stdlibs(excluded_stdlibs)
    puts "Adding ruboto.yml: #{excluded_stdlibs.join(' ')}"
    File.open('ruboto.yml', 'w') { |f| f << YAML.dump({:excluded_stdlibs => excluded_stdlibs}) }
  end

end
