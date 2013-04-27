lib = File.dirname(File.dirname(__FILE__)) + '/lib'
$:.unshift(lib) unless $:.include?(lib)
require 'test/unit'
require 'rubygems'
require 'fileutils'
require 'yaml'
require 'ruboto/sdk_versions'
require 'ruboto/sdk_locations'

module RubotoTest
  include Ruboto::SdkVersions
  include Ruboto::SdkLocations

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

  def self.version_from_device
    puts 'Reading OS version from device/emulator'
    system 'adb wait-for-device'
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
    raise 'Unable to read device/emulator apilevel'
  end

  def self.install_jruby_jars_gem
    jars_version_from_env = ENV['JRUBY_JARS_VERSION'] unless RUBOTO_PLATFORM == 'CURRENT'
    version_requirement = " -v #{jars_version_from_env}" if jars_version_from_env
    `gem query -i -n jruby-jars#{version_requirement}`
    unless $? == 0
      local_gem_file = "jruby-jars-#{jars_version_from_env}.gem"
      if File.exists?(local_gem_file)
        system "gem install -l #{local_gem_file} --no-ri --no-rdoc"
      else
        Dir.chdir('tmp') do
          system "gem install -r jruby-jars#{version_requirement} --no-ri --no-rdoc"
        end
      end
    end
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

  RUBOTO_PLATFORM = ENV['RUBOTO_PLATFORM'] || 'CURRENT'
  puts "RUBOTO_PLATFORM: #{RUBOTO_PLATFORM}"

  install_jruby_jars_gem unless RUBOTO_PLATFORM == 'CURRENT'

  if RUBOTO_PLATFORM == 'CURRENT'
    JRUBY_JARS_VERSION = Gem::Version.new('1.7.3')
  else
    # FIXME(uwe):  Simplify when we stop supporting rubygems < 1.8.0
    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
      gem_spec = Gem::Specification.find_by_path 'jruby-jars'
    else
      gem_spec = Gem.searcher.find('jruby-jars')
    end
    # EMXIF

    raise StandardError.new("Can't find Gem specification jruby-jars.") unless gem_spec
    JRUBY_JARS_VERSION = gem_spec.version
  end

  puts "JRUBY_JARS_VERSION: #{JRUBY_JARS_VERSION}"
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
    # FIXME(uwe): Remove exclusion feature
    excluded_stdlibs = options.delete(:excluded_stdlibs)
    included_stdlibs = options.delete(:included_stdlibs)
    standalone = options.delete(:standalone) || !!included_stdlibs  || !!excluded_stdlibs || ENV['RUBOTO_PLATFORM'] == 'STANDALONE'
    bundle = options.delete(:bundle)
    raise "Unknown options: #{options.inspect}" unless options.empty?
    Dir.mkdir TMP_DIR unless File.exists? TMP_DIR

    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
    template_dir = "#{APP_DIR}_template_#{$$}"
    template_dir << "_example_#{example}" if example
    template_dir << "_bundle_#{[*bundle].join('_')}" if bundle
    template_dir << '_updated' if update
    template_dir << '_standalone' if standalone
    template_dir << "_without_#{excluded_stdlibs.map { |ed| ed.gsub(/[.\/]/, '_') }.join('_')}" if excluded_stdlibs
    template_dir << "_with_#{included_stdlibs.map { |ed| ed.gsub(/[.\/]/, '_') }.join('_')}" if included_stdlibs
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
            FileUtils.rm(Dir['libs/{jruby-*.jar,dx.jar}'])
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
        Dir.chdir APP_DIR do
          write_gemfile(bundle) if bundle
          if standalone
            include_stdlibs(included_stdlibs) if included_stdlibs
            exclude_stdlibs(excluded_stdlibs) if excluded_stdlibs
            system "#{RUBOTO_CMD} gen jruby"
            raise "update jruby failed with return code #$?" if $? != 0
          end
        end
      end

      # FIXME(uwe): Installation with dx.jar fails on Android < 4.0.3 due to complex interface structure
      # Fixme(uwe): Remove when solved
      #if standalone && ANDROID_OS < 15
      #  Dir.chdir APP_DIR do
      #    puts "Removing dx.jar for android-#{ANDROID_OS}"
      #    FileUtils.rm(Dir['libs/dx.jar'])
      #  end
      #end
      # EMXIF

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
    check_platform_installation
    Dir.chdir APP_DIR do
      system 'rake test:quick'
      assert_equal 0, $?, "tests failed with return code #$?"
    end
  end

  def check_platform_installation
    if RUBOTO_PLATFORM == 'STANDALONE'
      system 'rake platform:uninstall'
    elsif RUBOTO_PLATFORM == 'CURRENT'
      system 'rake platform:current'
    elsif RUBOTO_PLATFORM == 'FROM_GEM'
      system 'rake platform:install'
    else
      fail "Unknown Ruboto platform: #{RUBOTO_PLATFORM.inspect}"
    end
    if $? != 0
      FileUtils.rm_rf 'tmp/RubotoCore'
      fail 'Error (un)installing RubotoCore'
    end
  end

  def include_stdlibs(included_stdlibs)
    puts "Adding ruboto.yml: #{included_stdlibs.join(' ')}"
    File.open('ruboto.yml', 'w') { |f| f << YAML.dump({:included_stdlibs => included_stdlibs}) }
  end

  def exclude_stdlibs(excluded_stdlibs)
    puts "Adding ruboto.yml: #{excluded_stdlibs.join(' ')}"
    File.open('ruboto.yml', 'w') { |f| f << YAML.dump({:excluded_stdlibs => excluded_stdlibs}) }
  end

  def write_gemfile(bundle)
    gems = [*bundle]
    puts "Adding Gemfile.apk: #{gems.join(' ')}"
    File.open('Gemfile.apk', 'w') do |f|
      f << "source 'https://rubygems.org/'\n\n"
      gems.each{|g| f << "gem '#{g}'\n"}
    end
  end

end
