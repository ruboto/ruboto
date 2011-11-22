require 'test/unit'
require 'rubygems'
require 'fileutils'
require 'yaml'

module RubotoTest
  PROJECT_DIR = File.expand_path('..', File.dirname(__FILE__))
  $LOAD_PATH << PROJECT_DIR

  # FIXME(uwe):  Simplify when we stop supporting rubygems < 1.8.0
  if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
    gem_spec = Gem::Specification.find_by_path 'jruby-jars'
  else
    gem_spec = Gem.searcher.find('jruby-jars')
  end
  # FIXME end
  
  raise StandardError.new("Can't find Gem specification jruby-jars.") unless gem_spec
  JRUBY_JARS_VERSION = gem_spec.version

  # FIXME(uwe): Remove when we stop supporting JRuby 1.5.6
  ON_JRUBY_JARS_1_5_6 = JRUBY_JARS_VERSION == Gem::Version.new('1.5.6')

  PACKAGE = 'org.ruboto.test_app'
  APP_NAME = 'RubotoTestApp'
  TMP_DIR = File.join PROJECT_DIR, 'tmp'
  APP_DIR = File.join TMP_DIR, APP_NAME
  ANDROID_TARGET = ENV['ANDROID_TARGET'] || 'android-7'

  VERSION_TO_API_LEVEL = {
      '2.1' => 'android-7', '2.1-update1' => 'android-7', '2.2' => 'android-8',
      '2.3' => 'android-9', '2.3.1' => 'android-9', '2.3.2' => 'android-9',
      '2.3.3' => 'android-10', '2.3.4' => 'android-10',
      '3.0' => 'android-11', '3.1' => 'android-12', '3.2' => 'android-13',
      '4.0.1' => 'android-14',
  }

  def self.version_from_device
    puts "Reading OS version from device/emulator"
    system "adb wait-for-device"
    start = Time.now
    IO.popen('adb bugreport').each_line do |line|
      if line =~ /sdk-eng (.*?) .*? .*? test-keys/
        version = $1
        api_level = VERSION_TO_API_LEVEL[version]
        raise "Unknown version: #{version}" if api_level.nil?
        puts "Getting version from device/emulator took #{(Time.now - start).to_i}s"
        return api_level
      end
      if line =~ /\[ro\.build\.version\.sdk\]: \[(\d+)\]/
        return $1
      end
    end
    raise "Unable to read device/emulator apilevel"
  end

  ANDROID_OS = ENV['ANDROID_OS'] || version_from_device
  RUBOTO_CMD = "ruby -rubygems -I #{PROJECT_DIR}/lib #{PROJECT_DIR}/bin/ruboto"

  puts "ANDROID_OS: #{ANDROID_OS}"
end

class Test::Unit::TestCase
  include RubotoTest
  alias old_run run

  def run(*args, &block)
    mark_test_start("#{self.class.name}\##{method_name}")
    old_run(*args, &block)
    mark_test_end("#{self.class.name}\##{method_name}")
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
    log "Ended test #{test_name}: #{passed? ? 'PASSED' : 'FAILED'} after #{(Time.now - @start_time).to_i}s"
    log '=' * 80
    log
  end

  def log(message = '')
    puts message
    system "adb shell log -t 'RUBOTO TEST' '#{message}'"
  end

  def generate_app(options = {})
    with_psych = options.delete(:with_psych) || false
    update = options.delete(:update) || false
    excluded_stdlibs = options.delete(:excluded_stdlibs)
    raise "Unknown options: #{options.inspect}" unless options.empty?
    Dir.mkdir TMP_DIR unless File.exists? TMP_DIR

    if with_psych || excluded_stdlibs
      system 'rake platform:uninstall'
    else
      system 'rake platform:install'
    end
    if $? != 0
      FileUtils.rm_rf 'tmp/RubotoCore'
      fail 'Error (un)installing RubotoCore'
    end

    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
    template_dir = "#{APP_DIR}_template_#{$$}#{'_with_psych' if with_psych}#{'_updated' if update}#{"_without_#{excluded_stdlibs.join('_')}" if excluded_stdlibs}"
    if File.exists?(template_dir)
      puts "Copying app from template #{template_dir}"
      FileUtils.cp_r template_dir, APP_DIR, :preserve => true
    else
      if update
        Dir.chdir TMP_DIR do
          system "tar xzf #{PROJECT_DIR}/examples/RubotoTestApp_0.1.0_jruby_1.6.3.dev.tgz"
        end
        if ENV['ANDROID_HOME']
          android_home = ENV['ANDROID_HOME']
        else
          android_home = File.dirname(File.dirname(`which adb`))
        end
        Dir.chdir APP_DIR do
          File.open('local.properties', 'w') { |f| f.puts "sdk.dir=#{android_home}" }
          File.open('test/local.properties', 'w') { |f| f.puts "sdk.dir=#{android_home}" }
          FileUtils.touch "libs/psych.jar" if with_psych
          exclude_stdlibs(excluded_stdlibs) if excluded_stdlibs
          system "#{RUBOTO_CMD} update app"
          assert_equal 0, $?, "update app failed with return code #$?"
        end
      else
        puts "Generating app #{APP_DIR}"
        system "#{RUBOTO_CMD} gen app --package #{PACKAGE} --path #{APP_DIR} --name #{APP_NAME} --target #{ANDROID_TARGET} #{'--with-psych' if with_psych}"
        if $? != 0
          FileUtils.rm_rf APP_DIR
          raise "gen app failed with return code #$?"
        end
        if excluded_stdlibs
          Dir.chdir APP_DIR do
            exclude_stdlibs(excluded_stdlibs)
            system "#{RUBOTO_CMD} update jruby --force"
            raise "update jruby failed with return code #$?" if $? != 0
          end
        end
      end
      Dir.chdir APP_DIR do
        system 'rake debug'
        assert_equal 0, $?
      end
      puts "Storing app as template #{template_dir}"
      FileUtils.cp_r APP_DIR, template_dir, :preserve => true
    end
  end

  def cleanup_app
    # FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end

  def run_app_tests
    if ['android-7', 'android-8'].include? ANDROID_OS
      puts "Skipping instrumentation tests on #{ANDROID_OS} since they don't work."
    else
      Dir.chdir APP_DIR do
        system 'rake test:quick'
        assert_equal 0, $?, "tests failed with return code #$?"
      end
    end
  end

  def exclude_stdlibs(excluded_stdlibs)
    puts "Adding ruboto.yml: #{excluded_stdlibs.join(' ')}"
    File.open('ruboto.yml', 'w') { |f| f << YAML.dump({:excluded_stdlibs => excluded_stdlibs}) }
  end

end
